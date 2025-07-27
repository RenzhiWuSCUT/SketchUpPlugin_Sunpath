require 'json'
module SuperCat
  module Sunpath
    class SunpathTool
      include Window

      def initialize

        @xdown = 0
        @ydown = 0
        @path = []
        reset
        # info_shadow = Hash[['City', 'Country', 'DayOfYear', 'Latitude', 'Longitude', 'North'].map { |item| [item, []] }]
      end

      def activate
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        shadow_info["DisplayShadows"] = false  # Turn off shadows

        @ip = Sketchup::InputPoint.new
        @window ||= create_window
        show_dlg(@window) { init_window }
        Sketchup.active_model.active_view.invalidate
      end

      def deactivate(view)
        destroy_dlg(@window)
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        shadow_info["DisplayShadows"] = false  # Turn off shadows
        view.invalidate
      end

      def getExtents
        bb = Geom::BoundingBox.new
        bb.add [@ip].map(&:position)
        bb
      end

      def onCancel(flag, view)
        self.reset()
      end

      def reset()
        @path = []
        info_time_shadow = Sp.fetch_shadow_time
        info_time_now = Sp.fetch_time_now
        info_shadow = Sp.fetch_shadow_info

        @month = info_time_now[:month]
        @day = info_time_now[:day]
        @hour = info_time_now[:hour]
        @scale_sun_path = 5
        @lat = info_time_shadow['Latitude'] || 23.12
        @lon = info_time_shadow['Longitude'] || 113.30
        @time_zone = Sp.calculate_timezone(@lon)
        @city = info_time_shadow['City'] || 'Guangzhou'
        set_location_shadow(@city, @lon, @lat)
        info_shadow['DisplayShadows'] = true

        @north = 0
      end

      def onMouseMove(flags, x, y, view)
        @ip.pick view, x, y
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        @path = [ip2pt_z0(@ip)]
        model = Sketchup.active_model
        shadow_info = model.shadow_info
      end

      def draw(view)
        @ip.draw(view)
        view.line_width = 3
        view.draw_points([ip2pt_z0(@ip)], 10, 4, CLR_C:: OPT_PREVIEW_COLOR)
        view.draw_points(@path, 10, 4, CLR_C:: OPT_SELECTED_COLOR) if @path.size > 0
        # view.invalidate
      end

      private

      def ip2pt_z0(ip)
        pt = ip.position
        pt.z = 0
        pt
      end

      def create_window
        window = UI::HtmlDialog.new(OPTION_HTMLDLG)
        html_file = HTML_DIALOG_SUNPATH
        window.set_file(html_file)

        window.add_action_callback("update_scene") {Sunpath.operation('Update Scene'){update_scene}  }

        window.add_action_callback("domeSizeChange") { |dialog, token|
          data = token2data(token, :to_f)
          @scale_sun_path = Sp.nil_or_set(data[0], :to_f)
          Sketchup.active_model.active_view.invalidate
        }

        window.add_action_callback("callback_time") { |dialog, token|
          data = token2data(token)
          @month = data[0]
          @day = data[1]
          @hour = data[2]
          # p "month: #{@month}, day: #{@day}, hour: #{@hour}"
          alt_suns, azm_sums = redraw_position_sun
          refresh_azm_alt(azm_sums,alt_suns)
          set_shadow_vector
          Sketchup.active_model.active_view.invalidate
        }

        callback_dlg(window, "submit_location") { |data|
          info = data[0]
          @index = info['ID']
          @city = info['City']
          @lon = Sp.nil_or_set(info['Longitude'], :to_f)
          @time_zone = Sp.calculate_timezone(@lon)
          @lat = Sp.nil_or_set(info['Latitude'], :to_f)
        }

        window.set_on_closed { window = nil }



        window
      end

      def update_scene
        # info_time = Sp.fatch_shadow_time
        set_location_shadow(@city, @lon, @lat)
        @grp_sp.erase! if @grp_sp && !@grp_sp.deleted?

        info_grps = SunPath.creat_sun_path(
            {
                :cpt => @path[0],
                :longitude => @lon,
                :latitude => @lat,
                :cal_tzone => @time_zone,
                :month => @month,
                :day => @day,
                :hour => @hour,
                :scale_sun_path => @scale_sun_path,
            }
        )
        @grp_sp = info_grps[:grp_sp]
        @grp_sun = info_grps[:grps_sun][0]
        refresh_azm_alt(info_grps[:azm_sum], info_grps[:alt_sun])
      end

      def refresh_azm_alt(azms_sum, alts_sun)
        # language=JavaScript
        @window.execute_script("vm_local.azimuth = (#{azms_sum[0].round(2)})") if azms_sum && azms_sum != []
        @window.execute_script("vm_local.alitude = (#{alts_sun[0].round(2)})") if alts_sun && alts_sun != []
      end

      def init_window
        # language=JavaScript
        @window.execute_script('sp.gen_time_step()')
        init_window_time
        @window.execute_script('vm_dome_scale.scale=5')
        init_window_library
      end

      def init_window_time
        info_time_now = Sp.fetch_time_now
        # @window.execute_script("sp.vm_time_setting.change_day_step(#{info_time_now[:month]})")
        @window.execute_script("sp.vm_time_setting.selectTimeStateMonth(#{info_time_now[:month]})")
        @window.execute_script("sp.vm_time_setting.selectTimeStateDay(#{info_time_now[:day]})")
        @window.execute_script("sp.vm_time_setting.selectTimeStateHour(#{info_time_now[:hour]})")
      end

      def init_window_library
        # 读取json文件的内容
        file_content = File.read(LOCATION_CITIES_PATH)
        database = JSON.parse(file_content)
        database_js = database.map { |city| city.to_json }
        # print database
        # language=JavaScript
        @window.execute_script("sp.initLibrary(#{database_js})")
      end

      def redraw_position_sun()
        return [[], []] unless @grp_sp
        alt_suns = []; azm_sums = []
        Sunpath.operation('重绘太阳', true) {
          @grp_sun.erase! if @grp_sun && !@grp_sun.deleted?
          cenpt = @path[0] || ORIGIN
          angr_north, vec_north = Sunpath.angle2north(@north)
          scale = @scale_sun_path * 200; scale_sun = 1
          sc_sun = scale_sun * scale * 0.007
          projection = 0
          list_pattern = [[true]] * 8760

          sunpath = SunPath.new(@lat, @lon, @time_zone, scale, angr_north, cenpt)
          hours_sun_up_temp = 0
          hoys = Sunpath.get_hoys([@hour], [@day], [@month], 1)
          grp_sun = nil; grps_sun = []; positions_sun = []
          hoys.each { |hoy|
            d, m, h = Sunpath.hour2date(hoy, true)
            m += 1
            sunpath.sol_init_output(m, d, h, false)

            hours_sun_up_temp += 1 if sunpath.solAlt >= 0

            if sunpath.solAlt >= 0 && list_pattern[Sunpath.date2hour(m, d, h).round.to_i - 1]
              grp_sun, vec_sun, pt_sun = sunpath.get_pt_sun(sc_sun)
              grp_sun, pt_sun = Visualization.get_pt_sphere_sun(sc_sun, pt_sun, projection, cenpt, scale, @grp_sp)
              positions_sun << pt_sun
              grps_sun << grp_sun
              alt_suns << sunpath.solAlt.radians
              azm_sums << sunpath.get_azimuth(vec_sun, vec_north)
            end
          }
          colors = [Sp.m_color(255, 255, 0)] * positions_sun.size
          SunPath.color_sun(grps_sun, colors)

          @grp_sun = grp_sun
        }
        [alt_suns, azm_sums]
      end

      def set_shadow_vector()
        info_time_now = Sp.fetch_time_now
        info_shadow_time = {:year => info_time_now[:year],
                            :month => @month,
                            :day => @day,
                            :hour => @hour,
                            :lon => @lon,
                            :lat => @lat,
                            :minute => info_time_now[:minute],
                            :second => info_time_now[:second]
        }
        set_time_shadow(info_shadow_time)
      end

      def set_time_shadow(info_shadow_time)
        time = Sp.info_time2time_1(info_shadow_time)
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        shadow_info["ShadowTime"] = time
        shadow_info["Latitude"] = info_shadow_time[:lat]
        shadow_info["Longitude"] = info_shadow_time[:lon]
        Sketchup.active_model.shadow_info['Dark'] = 30
        Sketchup.active_model.shadow_info['Light'] = 70
        # p "shadow_info= " + shadow_info.to_a.to_s + "【rzw_microclimate/tool/sun_path_tool.rb:251】"
      end

      def set_location_shadow(city, lon, lat, timezone = 8)
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        shadow_info['City'] = city
        shadow_info['Longitude'] = lon
        shadow_info['Latitude'] = lat
        shadow_info['TZOffset'] = timezone # 不应该设置时区偏移，因为SU里面的时间已经是本初子午线的时间
      end


      # def update_webdialog
      #   @window.execute_script('selectDomSize(5)')
      # end

    end

    class SunPath < Sp
      attr_accessor :time, :julianDay, :solDec, :solTime, :zenith, :solAlt, :solAz

      def initialize(latitude, longtitude = 0, time_zone = 0, scale = 100, angr_north = 0, cenpt = ORIGIN)
        @s_lat = latitude.to_f.degrees
        @s_lon = longtitude.degrees
        @s_meridian = (time_zone * 15).degrees
        @angr_north = angr_north
        @cenpt = cenpt
        @scale_sun_path = scale
        @time_zone = time_zone
      end

      # Purpose: 【sunPosPt】
      def get_pt_sun(sc_sun = 1)
        vec_tr = Sp.m_vec_by_y(@scale_sun_path)
        pt_base = @cenpt.transform(vec_tr)
        pt_base = pt_base.transform(Sp.m_rotate(@cenpt, X_AXIS, @solAlt))
        pt_base = pt_base.transform(Sp.m_rotate(@cenpt, Z_AXIS, -(@solAz - @angr_north)))
        vec_sun = pt_base.vector_to(@cenpt).normalize
        [nil, vec_sun, pt_base]
      end

      def get_azimuth(vec_sun, vec_north)
        vec_sun_new = vec_sun.reverse
        Sp.angle_in_plane(vec_north, vec_sun_new).radians
      end

      #This part is written by Trygve Wastvedt (Trygve.Wastvedt@gmail.com).
      def sol_init_output(month, day, hour, solar_time = false)

        def cal_julian_day(day, hour, month)
          year_default = 2018
          a = month < 3 ? 1 : 0
          y = year_default + 4800 - a
          m = month + 12 * a - 3
          julian_day = day + ((153 * m + 2) / 5).floor + 59
          julian_day += (hour - @time_zone) / 24.0 + 365 * y + (y / 4).floor - (y / 100).floor + (y / 400).floor - 32045.5 - 59
        end

        # Purpose: 【计算儒略日】
        julian_day = cal_julian_day(day, hour, month)
        julian_century = (julian_day - 2451545) / 36525
        #degrees
        geom_mean_long_sun = (280.46646 + julian_century * (36000.76983 + julian_century * 0.0003032)) % 360
        #degrees
        geom_mean_anom_sun = 357.52911 + julian_century * (35999.05029 - 0.0001537 * julian_century)
        eccent_orbit = 0.016708634 - julian_century * (0.000042037 + 0.0000001267 * julian_century)
        #degrees
        sun_eq_of_ctr = Math.sin(geom_mean_anom_sun.degrees) * (1.914602 - julian_century * (0.004817 + 0.000014 * julian_century)) +
            Math.sin(2 * geom_mean_anom_sun.degrees) * (0.019993 - 0.000101 * julian_century) +
            Math.sin(3 * geom_mean_anom_sun.degrees) * 0.000289
        #degrees
        sun_true_long = geom_mean_long_sun + sun_eq_of_ctr
        #degrees
        sun_app_long = sun_true_long - 0.00569 - 0.00478 * Math.sin((125.04 - 1934.136 * julian_century).degrees)
        #degrees
        mean_obliq_ecliptic = 23 + (26 + ((21.448 - julian_century * (46.815 + julian_century * (0.00059 - julian_century * 0.001813)))) / 60) / 60
        #degrees
        oblique_corr = mean_obliq_ecliptic + 0.00256 * Math.cos((125.04 - 1934.136 * julian_century).degrees)

        sol_dec = Math.asin(Math.sin(oblique_corr.degrees) * Math.sin(sun_app_long.degrees))
        var_y = Math.tan((oblique_corr / 2).degrees) * Math.tan((oblique_corr / 2).degrees)

        #minutes
        eq_of_time = 4 * (var_y * Math.sin(2 * geom_mean_long_sun.degrees) -
            2 * eccent_orbit * Math.sin(geom_mean_anom_sun.degrees) +
            4 * eccent_orbit * var_y * Math.sin(geom_mean_anom_sun.degrees) * Math.cos(2 * geom_mean_long_sun.degrees) -
            0.5 * (var_y ** 2) * Math.sin(4 * geom_mean_long_sun.degrees) -
            1.25 * (eccent_orbit ** 2) * Math.sin(2 * geom_mean_anom_sun.degrees)).radians

        #hours
        sol_time =
            solar_time ? hour : ((hour * 60 + eq_of_time + 4 * @s_lon.radians - 60 * @time_zone) % 1440) / 60

        #degrees
        angd_hour = (sol_time * 15 < 0) ? (sol_time *15 + 180) : (sol_time * 15 - 180)

        #RADIANS
        zenith = Math.acos(Math.sin(@s_lat) * Math.sin(sol_dec) + Math.cos(@s_lat) * Math.cos(sol_dec) * Math.cos(angd_hour.degrees))
        sol_alt = (PI / 2) - zenith

        if angd_hour == 0.0 || angd_hour == -180.0 || angd_hour == 180.0
          sol_az = (sol_dec < @s_lat) ? PI : 0.0
        else
          temp1 = ((Math.acos(((Math.sin(@s_lat) * Math.cos(zenith)) - Math.sin(sol_dec)) / (Math.cos(@s_lat) * Math.sin(zenith))) + PI) % (2 * PI))
          temp2 = ((3 * PI - Math.acos(((Math.sin(@s_lat) * Math.cos(zenith)) - Math.sin(sol_dec)) / (Math.cos(@s_lat) * Math.sin(zenith)))) % (2 * PI))
          sol_az = (angd_hour > 0) ? temp1 : temp2
        end

        @time = hour; @julianDay = julian_day; @solDec = sol_dec; @solTime = sol_time
        @zenith = zenith; @solAlt = sol_alt; @solAz = sol_az

      end

      def draw_daily_path(month, day, grp_parent = nil, cut_level = true)
        grp_daily_path = Sp.gen_grp_or_by_grp(grp_parent)
        ents_daily_path = grp_daily_path.entities

        hours = [0, 11.9, 12.1]
        poss_sun = []
        circle_valid = false
        hours.each do |hour|
          sol_init_output(month, day, hour)
          pos_sun = get_pt_sun[2]
          poss_sun << pos_sun
          circle_valid = true if pos_sun.z > @cenpt.z
        end

        if circle_valid
          Sp.m_circle_by_3pts(ents_daily_path, *poss_sun)
          cut_edges_below_pt(ents_daily_path, @cenpt) if cut_level
          # point = Geom.intersect_line_plane(circle, plane)
          # p "point = " + point.to_s + "【rzw_microclimate/plot3d/sun_path.rb:130】"
          # intersect with the plane
        end
        grp_daily_path

      end

      def draw_sun_path(solar_time, grp_parent = nil, cut_level = true)
        grp_sun_path = Sp.gen_grp_or_by_grp(grp_parent)
        ents_sun_path = grp_sun_path.entities

        grps_monthly = []
        (1..12).each do |m|
          grp_daily_path = draw_daily_path(m, 21, grp_parent, cut_level)
          grps_monthly << grp_daily_path if grp_daily_path
        end

        crvs_hourly = []
        days = [1, 7, 14, 21]
        sunP = []; hours_sel = []
        month = @s_lat.radians > 0 ? 6 : 12

        (0..24).each do |hour|
          sol_init_output(month, 21, hour, solar_time)
          hours_sel << hour if get_pt_sun[2].z > @cenpt.z
        end

        sunPsolarTimeL = []; hourlyCrvsSolarTime = []
        hours_sel.each do |h|
          days.each { |d|
            sunP = []
            (1..12).each { |m| sol_init_output(m, d, h, solar_time); sunP << get_pt_sun[2] }
          }
          sunP << sunP[0]
          sunPsolarTimeL << [sunP[11], Sp.m_cpt(sunP[0], sunP[10]), Sp.m_cpt(sunP[1], sunP[9]),
                             Sp.m_cpt(sunP[2], sunP[8]), Sp.m_cpt(sunP[3], sunP[7]),
                             Sp.m_cpt(sunP[4], sunP[6]), sunP[5]]
          crvs_solar_time = TSpline.add_tspline(ents_sun_path, sunP)
          cut_edges_below_pt(ents_sun_path, @cenpt) if cut_level # 没有这一句cut_level
          hourlyCrvsSolarTime << crvs_solar_time if crvs_solar_time
          # Sp.add_polyline(ents_path, sunP)
        end

        [grp_sun_path, grps_monthly]

      end

      def self.creat_sunpath_section(info)

        Sunpath.operation('绘制太阳路径') {
          # Purpose: 【输入的参数,后期整理出UI】
          longitude = info[:longitude] || 113.32 #116.388330
          latitude = info[:latitude] || 23.13 #39.928890
          time_zone = 8.0
          north = 0
          cenpt = info[:cpt] || ORIGIN
          scale_sun_path = info[:scale_sun_path] || 5
          scale_sun = 1
          step_time = 1
          # Purpose: 【创建组】
          grp_sp = gen_group
          # Purpose: 【初步处理输入的参数】
          angr_north, vec_north = Sunpath.angle2north(north)
          scale = scale_sun_path * 200
          sc_sun = scale_sun * scale * 0.007

          # Purpose: 【确定hoys】
          day, month = [:day, :month].map { |key| info[key] }
          hours = (0..23).map { |v| v }
          days = [day] * 24
          months = [month] * 24
          hoys = Sunpath.get_hoys(hours, days, months, step_time)

          # Purpose: 【构建SunPath实例】
          sunpath = SunPath.new(latitude, longitude, time_zone, scale, angr_north, cenpt)

          # Purpose: 【根据hoys计算pt_sunL】
          pt_sunL = []
          flags_hour_time = []
          hoys.each { |hoy|
            d, m, h = Sunpath.hour2date(hoy, true); m += 1

            [7.5, 22.5, 37.5, 52.5].each { |minute| # todo 要全部错位一半 [7.5, 22.5, 37.5, 52.5]
              sunpath.zenith, sunpath.solAz, sunpath.solAlt =
                  MRTCalCUDA.noaaSolarCalculator(latitude, longitude, time_zone, m, d, h, minute).map { |val| val.degrees }
              if sunpath.solAlt > 0
                grp_sun, vec_sun, pt_sun = sunpath.get_pt_sun(sc_sun)
                pt_sunL << pt_sun
              end
            }
            [0].each { |minute| # todo 要全部错位一半 [7.5, 22.5, 37.5, 52.5]
              sunpath.zenith, sunpath.solAz, sunpath.solAlt =
                  MRTCalCUDA.noaaSolarCalculator(latitude, longitude, time_zone, m, d, h, minute).map { |val| val.degrees }
              if sunpath.solAlt > 0
                grp_sun, vec_sun, pt_sun = sunpath.get_pt_sun(sc_sun)
                flags_hour_time << (minute == 0 ? [h, pt_sun] : false)
              end

            }
          }

          # Purpose: 【根据pt_sunL绘制扇子mesh】
          # >>>> Purpose【构建mesh】
          mesh = Geom::PolygonMesh.new
          mesh.add_point(cenpt)
          pt_sunL.each { |pt| mesh.add_point(pt) }
          pt_sunL.each_with_index { |pt, i|
            next if i == 0
            polygon_index = mesh.add_polygon(1, i, i + 1)
          }

          # >>>> Purpose【构建材质】
          material_exposure = Sp.set_material("sunpath_section_exposure", "yellow", 0.5)
          material_hemi_shaded = Sp.set_material("sunpath_section_exposure", "green", 0.5)
          material_shaded = Sp.set_material("sunpath_section_shaded", "blue", 0.5) # 浅蓝

          # >>>> Purpose【fill_from_mesh】
          smooth_flags = Geom::PolygonMesh::SMOOTH_SOFT_EDGES
          grp_sp.entities.fill_from_mesh(mesh, true, smooth_flags)

          # >>>> Purpose【由射线求交添加颜色】
          model = Sketchup.active_model
          faces = grp_sp.entities.grep(Sketchup::Face)
          tran = grp_sp.transformation
          grp_sp.visible = false
          z_level = cenpt.z
          faces.each { |face|
            pts_face = Sp.face2pts_outer_inner(face, tran)[1]
            pts_side = pts_face.reject { |pt| pt.z <= z_level }
            next unless pts_side.size == 2
            cpt_side = Sp.m_cpt(*pts_side)
            vec = cenpt.vector_to(cpt_side)
            ray_pt = cenpt
            flag_break = true
            # >>>> Purpose【射线求交】
            flag_0sky_1build_2tree = nil
            while true
              ray = [ray_pt, vec]
              res_raytest = model.raytest(ray, true)
              if res_raytest.nil? # Purpose: 【射到天空】
                flag_0sky_1build_2tree ||= 0
                flag_break = true
              else
                face_hitted = res_raytest.last.last
                if Sp.face_hitted_is_stuff_transmit?(face_hitted) # Purpose: 【射到树或遮阳板】
                  flag_0sky_1build_2tree = 2
                  flag_break = false
                  ray_pt = res_raytest.first
                else
                  flag_0sky_1build_2tree = 1
                  flag_break = true
                end
              end
              break if flag_break
            end
            # >>>> Purpose【根据求交结果染色】
            if flag_0sky_1build_2tree == 0
              Sp.set_face_material_defined(face, material_exposure)
            elsif flag_0sky_1build_2tree == 1
              Sp.set_face_material_defined(face, material_shaded)
            elsif flag_0sky_1build_2tree == 2
              Sp.set_face_material_defined(face, material_hemi_shaded)
            end
          }
          grp_sp.visible = true

          # >>>> Purpose【整点报时】
          flags_hour_time.each_with_index { |flag, i_flag|
            if flag
              hour, pt_sun = flag

              # >>>> Purpose【绘制参考点】
              grp_sp.entities.add_cpoint(pt_sun)
              # >>>> Purpose【绘制整点时间】
              pt_text = pt_sun.clone
              factor_z_text = scale * 0.2 # + Math.log(12 - (hour - 12).abs - 2) * 0.2
              pt_text.z = pt_text.z + factor_z_text
              # text = grp_sp.entities.add_text("#{'%02d' % hour}:30", pt_sun, pt_sun.vector_to(pt_text)) # 绘制半点时间
              text = grp_sp.entities.add_text("#{'%02d' % hour}:00", pt_sun, pt_sun.vector_to(pt_text)) # 绘制整点时间
              text.display_leader = true
              text.arrow_type = 3
              text.leader_type = 0
              text.line_weight = 1

            end
          }

          # Purpose: 【return info】
          {
              :grp_sp => grp_sp,
          }
        }

      end


      def self.creat_sun_path(info)

        Sunpath.operation('绘制太阳路径') {
          # Purpose: 【输入的参数,后期整理出UI】
          longitude = info[:longitude] || 113.32 #116.388330
          latitude = info[:latitude] || 23.13 #39.928890
          time_zone = 8.0
          north = 0
          cenpt = info[:cpt] || ORIGIN
          scale_sun_path = info[:scale_sun_path] || 5
          scale_sun = 1
          step_time = 1
          period_analysis = 0 # [[1, 1, 1], [12, 31, 24]]
          solar_or_standard_time = false
          daily_or_annual_sun_path = true

          if daily_or_annual_sun_path
            path_sun_daily, path_sun_annual = [false, true]
          else
            path_sun_daily, path_sun_annual = [true, false]
          end

          day = [info[:day] || 21]
          hour = [info[:hour] || 12.0]
          month = [info[:month] || 12]

          # 0 = 3D hemisphere
          # 1 = Orthographic (straight projection to the XY Plane)
          # 2 = Stereographic (equi-angular projection to the XY Plane)
          projection = 0


          # Purpose: 【创建组】
          grp_sp = gen_group

          # Purpose: 【初步处理输入的参数】
          angr_north, vec_north = Sunpath.angle2north(north)
          scale = scale_sun_path * 200
          sc_sun = scale_sun * scale * 0.007

          if period_analysis != 0 && period_analysis[0] != 0
            hoys, months, days = Sunpath.get_hows_based_on_period(period_analysis, step_time)
          else
            days = day; months = month; hours = hour
            hoys = Sunpath.get_hoys(hours, days, months, step_time)
          end

          # todo conditionalStatement
          list_pattern = [[true]] * 8760
          statement_title = false
          latitude = Sunpath.check_latitude(latitude)

          sunpath = SunPath.new(latitude, longitude, time_zone, scale, angr_north, cenpt)
          positions_sun = []; hours_sun_up = []; info_pos_sun = []
          vecs_sun = []; grps_sun = []; grps_compass_num = []; alt_sun = []; azm_sum = []

          Sunpath.process('绘制太阳') {
            hours_sun_up_temp = 0
            hoys.each { |hoy|
              d, m, h = Sunpath.hour2date(hoy, true)
              m += 1
              sunpath.sol_init_output(m, d, h, solar_or_standard_time)
              # p [sunpath.time, sunpath.julianDay, sunpath.solDec.radians, sunpath.solTime.radians, sunpath.zenith.radians, sunpath.solAlt.radians, sunpath.solAz.radians].to_s

              hours_sun_up_temp += 1 if sunpath.solAlt >= 0

              if sunpath.solAlt >= 0 && list_pattern[Sunpath.date2hour(m, d, h).round.to_i - 1]

                grp_sun, vec_sun, pt_sun = sunpath.get_pt_sun(sc_sun)
                grp_sun, pt_sun = Visualization.get_pt_sphere_sun(sc_sun, pt_sun, projection, cenpt, scale, grp_sp)

                hours_sun_up << Sunpath.date2hour(m, d, h)
                info_pos_sun << Sunpath.hour2date(Sunpath.date2hour(m, d, h))
                positions_sun << pt_sun
                grps_sun << grp_sun
                vecs_sun << vec_sun
                alt_sun << sunpath.solAlt.radians
                azm_sum << sunpath.get_azimuth(vec_sun, vec_north)
              end
            }
          }
          colors = [m_color(255, 255, 0)] * positions_sun.size
          color_sun(grps_sun, colors)

          # if vecs_sun.size==0 # conditionalStatement
          grps_sunpath_daily = []
          crvs_path_sun_annual = []
          grps_sunpath = []; grps_sunpath_monthly = []
          Sunpath.process('绘制太阳路径') {
            grp_sunpath, grps_sunpath_monthly = sunpath.draw_sun_path(solar_or_standard_time, grp_sp)[0] if path_sun_annual != false
            if path_sun_daily
              grps_sunpath_daily = []
              hoys.each { |hoy|
                d, m, h = Sunpath.hour2date(hoy, true)
                m += 1
                grps_sunpath_daily << sunpath.draw_daily_path(m, d, grp_sp)
              }
            end
            grps_sunpath << grp_sunpath
          }

          crvs_base = []; grps_base = []
          Sunpath.process('绘制底线') {
            grp_base = gen_grp_or_by_grp(grp_sp)
            ents_base = grp_base.entities
            if path_sun_annual || path_sun_daily
              crvs_base = [ents_base.add_circle(cenpt, Z_AXIS, (1.08 * scale), 48)]
            end
            grps_base << grp_base
          }

          crvs_path_sun = []
          crvs_path_sun += crvs_path_sun_annual if crvs_path_sun_annual
          crvs_path_sun += grps_sunpath_daily if grps_sunpath_daily
          info_bb = Visualization.calculate_bb(crvs_base, true) # if crvs_path_sun != []

          if projection == 1 || projection == 2
            Visualization.projectGeo(crvs_path_sun, projection, cenpt, scale)
          end

          text_legend = []; pt_text = []; faces_legned = nil; title = []
          heading_custom = "\n\n\n\nSun-Path Diagram - Latitude: " + latitude.to_s + "\n"

          # statement
          grps_compass = []
          Sunpath.process('绘制文字') {
            if path_sun_daily || path_sun_annual
              if grps_sun.size == 1
                d, m, h = Sunpath.hour2date(hoys[0], true)
                m += 1
                heading_custom = heading_custom + "\n" + Sunpath.hour2date(Sunpath.date2hour(m, d, h)) +
                    ', ALT = ' + ("%.2f" % alt_sun[0]) + ', AZM = ' + ("%.2f" % azm_sum[0]) + '\n'
              elsif months.size == 1 && days.size == 1
                m = Sunpath.check_month(months.first.to_i)
                d = Sunpath.check_day(days.first.to_i, m)
                heading_custom = heading_custom + "\n" + d.to_s + ' ' + LIST_MONTH[m - 1]
              end

              pars_legend = []
              pars_legend << [] if pars_legend.size == 0

              legend = []; size_text = nil; info_par_legend = nil; pt_base_title = nil
              Sunpath.process('绘制标题') {
                info_par_legend = Sunpath.read_paras_legend(pars_legend[0])
                size_text = info_par_legend[:legendScale] * 0.5 * info_bb[:BBYlength] / 20
                pt_base_title = info_bb[:titleBasePt]
                # curve_text_title = Visualization.text2srf(["\n\n" + heading_custom],
                #                                           [pt_base_title],
                #                                           'Veranda',
                #                                           size_text,
                #                                           info_par_legend[:legendBold])
                curve_text_title = [[nil]] # 先不画标题
                legend = curve_text_title.flatten
                text_legend << "\n\n" + heading_custom
                pt_text << pt_base_title
              }


              Sunpath.process('绘制指针') {
                # Purpose: 【绘制内外圆】
                grp_compass, pts_text_compass, text_compass =
                    Visualization.make_circle_compass(grp_sp, cenpt, vec_north, scale, frange_pop(0, 360, 30))

                #projection
                # Purpose: 【绘制文字】
                faces_compass_num, grp_compass_num = Visualization.text2face(text_compass,
                                                                             pts_text_compass,
                                                                             'Times New Romans',
                                                                             size_text / 1.5,
                                                                             info_par_legend[:legendBold],
                                                                             grp_sp)
                # crvs_compass = crvs_init_compass + faces_compass_num.flatten
                text_legend << text_compass
                grps_compass << grp_compass
                grps_compass_num << grp_compass_num
                # pt_text << pts_text_compass
              }

            end
          }

          {
              :grp_sp => grp_sp,
              :grps_sun => grps_sun,
              :grps_sunpath => grps_sunpath,
              :grps_sunpath_monthly => grps_sunpath_monthly,
              :grps_sunpath_daily => grps_sunpath_daily,
              :grps_base => grps_base,
              :grps_compass => grps_compass,
              :grps_compass_num => grps_compass_num,
              :azm_sum => azm_sum,
              :alt_sun => alt_sun
          }
          # [[positions_sun], [joined_sun_all], vecs_sun, [crvs_path_sun],
          #  [crvs_compass_all], [crvs_angle], [[]], [values_all],
          #  alt_sun, azm_sum, [cenpt], [info_pos_sun],
          #  [], [hours_sun_up], [legend_all], [points_base_title]]
        }

      end

      def self.color_sun(grps_sun, colors)
        faces_suns = []
        colors_reperted = []
        grps_sun.each_with_index do |grp_sun, i_sun|
          set_color2grp(grp_sun, i_sun.to_s, colors[i_sun], 255)
        end
        grps_sun
      end

      private

      def cut_edges_below_pt(ents_path, pt_level)
        level = pt_level.z
        to_erase = []
        plane = [pt_level, Z_AXIS]

        edges = ents_path.grep(Sketchup::Edge)
        edges.each do |edge|
          line = edge.line
          if line.all? { |pt| pt.z <= level }
            to_erase << edge
          elsif line.any? { |pt| pt.z < level }
            intersection = Geom.intersect_line_plane(line, plane)
            edge.split(intersection)
          end
        end

        edges_second = ents_path.parent.entities.grep(Sketchup::Edge) - to_erase
        edges_second.each { |edge|
          if edge.vertices.map(&:position).all? { |pt| pt.z <= level }
            to_erase << edge
          end
        }
        to_erase
        ents_path.erase_entities(to_erase)
      end

    end

    class TSpline < Sp

      def self.add_tspline(ents, pts, precision = 5)
        return nil if pts.nil? || pts.size < 3

        crvs = []
        pts.each_index do |i|
          next if i == 0 || i == pts.size - 1
          next unless i % 2 == 1
          pt_l = pts[i - 1]
          pt_t = pts[i]
          pt_n = pts[i + 1]
          lpt = curve([pt_l, pt_t, pt_n], precision)
          add_polyline(ents, lpt)
          crvs << lpt
        end
        crvs.flatten
        # crvpts = curve(pts, 2)
        # add_polyline(ents, crvpts)
      end


      def self.curve(pts_orig, precision)
        #Computing the bissector for each original control points
        order = 3
        order = pts_orig.length if order > pts_orig.length
        nbpts = pts_orig.length - 2
        vplane = []
        result = []
        pts = [pts_orig.first]
        for i in 1..nbpts
          vec1 = pts_orig[i].vector_to(pts_orig[i - 1]).normalize
          break if (pts_orig[i] == pts_orig[i + 1])
          vec2 = pts_orig[i].vector_to(pts_orig[i + 1]).normalize
          vbis = vec1 + vec2
          normal = (vbis.valid?) ? vbis * (vec1 * vec2) : vec1
          vplane[i] = [pts_orig[i], normal]
          pts[i] = pts_orig[i]
        end

        #Iteration on moving control points
        pts += [pts_orig.last]
        factor = 1.5

        curve = compute_bspline pts_orig, precision, order
        for iter in 0..2
          ptinter = compute_intersect pts_orig, curve, vplane
          next unless ptinter.length > 0
          for i in 1..nbpts
            next unless ptinter[i]
            d = pts_orig[i].distance(ptinter[i])
            vec = ptinter[i].vector_to pts_orig[i]
            pts[i] = pts[i].offset vec, d * factor if vec.valid?
          end
          curve = compute_bspline pts, precision, order

        end
        return curve
      end

      def self.compute_intersect(pts, curve, vplane)
        nbpts = pts.length - 2
        nbcurve = curve.length - 2
        ptinter = [curve[0]]
        jbeg = 0
        for i in 1..nbpts
          for j in jbeg..nbcurve
            begin
              pt = intersect_segment_plane(curve[j], curve[j + 1], vplane[i])
            rescue
              break
            end
            if pt
              ptinter[i] = pt
              jbeg = j
              break
            end
          end
        end
        ptinter += [curve.last]
        return ptinter
      end

      def self.compute_bspline(pts, numseg, order)
        #initialization
        curve = []
        nbpts = pts.length
        kmax = nbpts + order - 1

        #Generating the uniform open knot vector
        knot = []
        knot[0] = 0.0
        for i in 1..kmax
          knot[i] = ((i >= order) && (i < nbpts + 1)) ? knot[i - 1] + 1.0 : knot[i - 1]
        end

        #calculate the points of the B-Spline curve
        t = 0.0
        step = knot[kmax] / numseg
        for icrv in 0..numseg
          #calculate parameter t
          t = knot[kmax] if (knot[kmax] - t) < 0.0000001

          #calculate the basis
          basis = bspline_basis order, t, nbpts, knot

          #Loop on the control points
          pt = Geom::Point3d.new
          pt.x = pt.y = pt.z = 0.0
          for i in 0..(nbpts - 1)
            pt.x += basis[i] * pts[i].x
            pt.y += basis[i] * pts[i].y
            pt.z += basis[i] * pts[i].z
          end
          curve.push pt
          t += step
        end

        return curve
      end

      # given a nt integer (number of segments to interpolate) interpolate nt points of a segment
      def self.bspline_basis(order, t, nbpts, knot)
        basis = []
        kmax = nbpts + order - 1

        for i in 0..(kmax-1)
          basis[i] = (t >= knot[i] && t < knot[i+1]) ? 1.0 : 0.0
        end

        for k in 1..(order-1)
          for i in 0..(kmax-k-1)
            d = (basis[i] == 0.0) ? 0 : ((t - knot[i]) * basis[i]) / (knot[i+k] - knot[i])
            e = (basis[i+1] == 0.0) ? 0 : ((knot[i+k+1] - t) * basis[i+1]) / (knot[i+k+1] - knot[i+1])
            basis[i] = d + e
          end
        end
        basis[nbpts-1] = 1.0 if t == knot[kmax]

        return basis
      end

      def self.intersect_segment_plane(pt1, pt2, plane)
        pt = Geom.intersect_line_plane [pt1, pt2], plane
        return nil unless pt
        return pt if (pt == pt1) || (pt == pt2)
        vec1 = pt1.vector_to pt
        vec2 = pt2.vector_to pt
        (vec1 % vec2 <= 0) ? pt : nil
      end



    end

    class Visualization < Sp

      class Bitmap

        attr_reader(:data, :width, :height, :size)
        attr_accessor(:path) ### v1.0.0

        def initialize(*params)
          if params.length == 2
            img_width = params[0]
            img_height = params[1]
            @data = []
            @width = img_width
            @height = img_height
            for j in 0..(@height - 1)
              row = []
              for i in 0..(@width - 1)
                row[i] = [0, 0, 0]
              end
              @data[j] = row
            end
            padding = @width.divmod(4)[1]
            @size = 54 + (@width * 3 + padding) * @height
          elsif params.length == 1
            array = params[0]
            @data = array
            @width = array[0].length
            @height = array.length
            padding = @width.divmod(4)[1]
            @size = 54 + (@width * 3 + padding) * @height
          end
        end

        def write(file_name)
          header = 0.chr * 54
          header[0, 2] = 'BM'
          header[2, 4] = lbo_dword(@size) #? [@size].pack("V")
          header[10] = 54.chr
          header[14] = 40.chr
          header[18, 4] = lbo_dword(@width) #? [@width].pack("V")
          header[22, 4] = lbo_dword(@height) #? [@height].pack("V")
          header[26] = 1.chr
          header[28] = 24.chr
          header[34, 4] = lbo_dword(@size - 54) #? [@size-54].pack("V")
          header[38, 2] = 18.chr + 11.chr
          header[42, 2] = 18.chr + 11.chr

          begin
            file_path = @path.nil? ? file_name : File.join(@path, file_name)

            # unless File.exists?@path
            #   FileUtils.makedirs(@path)
            # end

            file = File.new(file_path, "wb")
            file.write(header)
            padding = @width.divmod(4)[1]
            for j in 0..(@height - 1)
              for i in 0..(@width - 1)
                b = @data[@height - 1 - j][i][2].chr
                g = @data[@height - 1 - j][i][1].chr
                r = @data[@height - 1 - j][i][0].chr
                file.write(b + g + r)
              end
              file.write(0.chr * padding)
            end
          rescue => e
            raise
          ensure
            file.close
          end
        end

        #} write()

        #{ blur()
        #
        # !! Bad style: making assignments within boolean expressions !!
        #
        def blur(size)
          size.times do
            data = []
            (0..@height - 1).each { |row|
              (0..@width - 1).each { |col|
                average = [[0, 0, 0], 0]
                if (row > 0) and ((pixel = @data[row - 1][col]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (row < @height - 1) and ((pixel = @data[row + 1][col]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (col > 0) and ((pixel = @data[row][col - 1]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (col < @width - 1) and ((pixel = @data[row][col + 1]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (row > 0) and (col > 0) and ((pixel = @data[row - 1][col - 1]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (row > 0) and (col < @width - 1) and ((pixel = @data[row - 1][col + 1]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (row < @height - 1) and (col > 0) and ((pixel = @data[row + 1][col - 1]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                if (row < @height - 1) and (col < @width - 1) and ((pixel = @data[row + 1][col + 1]) != 0)
                  average[0].offset!(pixel)
                  average[1] += 1
                end
                #
                if average[1] > 0
                  t = Geom::Transformation.scaling(1.0 / average[1])
                  data << [row, col, intized_array(average[0].transform(t))]
                end
                #
              }
            }
            #
            for pixel in data
              # row = pixel[0]
              # col = pixel[1]
              # rgb = pixel[2]
              @data[pixel[0]][pixel[1]] = pixel[2]
            end
            #
          end # size.times
        end

        #} blur()

        private

        #{ intized_array( xyz_array )
        #
        #  Returns a new array whose members are the truncated
        #   values of the xyz_array argument.
        #--
        #  Equiv to Ruby's: array.map {|n| n.to_i }
        #++
        def intized_array(ary) # called by blur()
          #
          return [ary.x.to_i, ary.y.to_i, ary.z.to_i]
          #
        end

        #} intized_array()


        #{ lbo_dword()
        #
        #  Outputs a 4-byte (32bit) DWORD String, in little-endian byte order.
        #
        # !! NEEDS OPTIMZING (outputs String)
        #    -> How about using Array.pack ?:  [n].pack("V")
        #
        def lbo_dword(n)
          n = n.to_i.to_s(16)
          n = '0' * (8 - n.length) + n # left pad with zeros
          n = n[6, 2].to_i(16).chr + n[4, 2].to_i(16).chr + n[2, 2].to_i(16).chr + n[0, 2].to_i(16).chr
        end #} lbo_dword()


        #{ from_byte() # <--<< NOT USED & mis-named: would take a 4 element array
        #
        # def from_byte(n)
        # n = (n[3].to_s(16)+n[2].to_s(16)+n[1].to_s(16)+n[0].to_s(16)).to_i(16)
        # end
        #} from_byte()


      end # class Bitmap


      def self.uv2xyz(xy_face2d, point_of_face, xaxis_of_face, yaxis_of_face)
        # Tips: 【数组被重载了x()和y(),分别为[1]和[2]】
        # Idea: 【叉积/外积/向量积: a向量与b向量的向量积的方向与这两个向量所在平面垂直】
        # Purpose: 【uv坐标转为三维坐标】
        point_of_face.offset([
                                 xaxis_of_face.x * xy_face2d.x + yaxis_of_face.x * xy_face2d.y,
                                 xaxis_of_face.y * xy_face2d.x + yaxis_of_face.y * xy_face2d.y,
                                 xaxis_of_face.z * xy_face2d.x + yaxis_of_face.z * xy_face2d.y
                             ])
      end

      def self.make_pos4material(pt_origin_of_face, step_uv, uv_max_face2d, uv_min_face2d, vector_xaxis_of_face, vector_yaxis_of_face)
        pos4material = [
            uv2xyz(uv_min_face2d, pt_origin_of_face, vector_xaxis_of_face, vector_yaxis_of_face),
            [0, 1, 0], # 左下为贴图Y轴末端参考位点
            uv2xyz([uv_max_face2d.x - step_uv, uv_max_face2d[1] - step_uv], pt_origin_of_face, vector_xaxis_of_face, vector_yaxis_of_face),
            [1, 0, 0], # 右上为贴图X轴末端参考位点
            uv2xyz([uv_min_face2d.x, uv_max_face2d[1] - step_uv], pt_origin_of_face, vector_xaxis_of_face, vector_yaxis_of_face),
            [0, 0, 0] # 右下为贴图原点
        ]
      end

      def self.createLegend4Mask(group, results, legendPar, boundingBoxP, color_mode)

        def self.legend(group, basePt, legendHeight, legendWidth, numOfSeg, textSize, color_mode, lowB, highB)

          basePt = basePt + Sp.m_vec_by_x(legendWidth)
          numPt = (4 + 2 * (numOfSeg - 1)).to_i

          # make the point list
          ptList = []
          (0...numPt).each do |i_pt|
            point = Sp.m_point(basePt.x + (i_pt % 2) * legendWidth, basePt.y + (i_pt / 2).to_i * legendHeight, basePt.z)
            ptList << point
          end

          meshVertices = ptList; textPt = []

          # (0...numPt).each do |i_pt|
          #   mesh_legend.add_point(ptList[i_pt])
          # end

          (0...numOfSeg).each_with_index do |segNum|
            # Purpose: 【textPt】
            pt = Sp.m_point(meshVertices[segNum * 2 + 1].x + textSize * 0.5,
                            meshVertices[segNum * 2 + 1].y,
                            meshVertices[segNum * 2 + 1].z)
            textPt << pt
          end

          if numOfSeg == 1
            colors = [Visualization.rgb(0.5, color_mode)]
          else
            list = Sp.linspace(lowB, highB, 10)
            colors = Visualization.valL2rgbL(color_mode, Sp.frange(1.0, numOfSeg.to_f, 1.0))
          end

          (0...numOfSeg).each_with_index do |segNum|
            # Purpose: 【mesh】
            mesh_legend = Geom::PolygonMesh.new
            mesh_legend.add_point(meshVertices[segNum * 2])
            mesh_legend.add_point(meshVertices[segNum * 2 + 1])
            mesh_legend.add_point(meshVertices[segNum * 2 + 2])
            mesh_legend.add_point(meshVertices[segNum * 2 + 3])
            mesh_legend.add_polygon(0 + 1, 1 + 1, 3 + 1, 2 + 1)
            smooth_flags = Geom::PolygonMesh::NO_SMOOTH_OR_HIDE
            material = Sp.set_material("legend_#{segNum + 1}", colors[segNum])
            group.entities.add_faces_from_mesh(mesh_legend, smooth_flags, material)
          end

          textPt << Sp.m_point(meshVertices[-1].x + textSize * 0.5, meshVertices[-1].y, meshVertices[-1].z)

          # group.entities.add_faces_from_mesh(my_mesh)
          textPt
        end

        contourLegend ||= false
        lowB, highB, numOfSeg, legendTitle, legendBasePoint, legendScale, font,
            textSize, fontBold, decimalPlaces, greaterLessThan, contourLegend =
            [:lowB, :highB, :numSeg, :legendTitle, :legendBasePoint, :legendScale, :legendFont,
             :legendFontSize, :legendBold, :decimalPlaces, :removeLessThan].map { |key| legendPar[key] }
        legendScale ||= 1; textSize ||= nil; font ||= nil; textSize ||= nil; fontBold ||= false

        numOfSeg = 6
        highB = 5.0
        lowB = 0.0
        basePt = legendBasePoint.nil? ? boundingBoxP.min : legendBasePoint

        if boundingBoxP
          bbylength = boundingBoxP.max.y - boundingBoxP.min.y
          maxBoundingValue = get_maxBoundingValue(boundingBoxP)
          bbylength = maxBoundingValue.to_i if bbylength < 1
        else
          bbylength = 10.0.m
        end
        font = 'Verdana' unless font
        legendHeight = legendWidth = (bbylength / 10) * legendScale
        textSize = (legendHeight / 3) * legendScale unless textSize
        # Modify【2021-06-30 23:58:40】【frange_pop变成frange】
        numbers = Sp.frange(lowB, highB, Sp.round((highB - lowB) / (numOfSeg - 1), 6))
        if numbers.size == 1
          numbers; numOfSeg = 1
        elsif numbers.size < numOfSeg
          numbers << highB
        elsif numbers.size > numOfSeg
          numbers = numbers[0...-1]
        end
        numbersStr = [MASK_C::NUN, MASK_C::BLD, MASK_C::ABR, MASK_C::ABR_INNER, MASK_C::GRY, MASK_C::SKY]
        # end

        # formatString = "%." + decimalPlaces.to_s + "f"
        # numbersStr = numbers.map { |x| formatString % x }
        # if numOfSeg == 1
        #   numbersStr[0] = "=" + numbersStr[0]
        # else
        #   unless greaterLessThan
        #     numbersStr[0] = "<=" + numbersStr[0]
        #     numbersStr[-1] = ">" + numbersStr[-1]
        #   end
        # end
        numbersStr << legendTitle
        numbers << legendTitle
        # todo 可去
        # Modify【2021-12-18 01:04:36】【】
        if numOfSeg < numbersStr.size - 1
          numOfSeg += 1
        end

        # legendColors = Visualization.gradientColor(numbers[0...-1], legendPar[:lowB], legendPar[:highB], colors)
        # mesh surfaces and legend text
        textPt = legend(group, basePt, legendHeight, legendWidth, numOfSeg, textSize, color_mode, lowB, highB)
        numbersCrv = text2face(numbersStr, textPt, font, textSize, fontBold, group)

        [numbers, numbersCrv, textPt, textSize]

      end

      def self.createLegend(group, results, legendPar, boundingBoxP, color_mode)

        def self.legend(group, basePt, legendHeight, legendWidth, numOfSeg, textSize, color_mode, lowB, highB)

          basePt = basePt + Sp.m_vec_by_x(legendWidth)
          numPt = (4 + 2 * (numOfSeg - 1)).to_i

          # make the point list
          ptList = []
          (0...numPt).each do |i_pt|
            point = Sp.m_point(basePt.x + (i_pt % 2) * legendWidth, basePt.y + (i_pt / 2).to_i * legendHeight, basePt.z)
            ptList << point
          end

          meshVertices = ptList; textPt = []

          # (0...numPt).each do |i_pt|
          #   mesh_legend.add_point(ptList[i_pt])
          # end

          (0...numOfSeg).each_with_index do |segNum|
            # Purpose: 【textPt】
            pt = Sp.m_point(meshVertices[segNum * 2 + 1].x + textSize * 0.5,
                            meshVertices[segNum * 2 + 1].y,
                            meshVertices[segNum * 2 + 1].z)
            textPt << pt
          end

          if numOfSeg == 1
            colors = [Visualization.rgb(0.5, color_mode)]
          else
            list = Sp.linspace(lowB, highB, 10)
            colors = Visualization.valL2rgbL(color_mode, Sp.frange(1.0, numOfSeg.to_f, 1.0))
          end

          (0...numOfSeg).each_with_index do |segNum|
            # Purpose: 【mesh】
            mesh_legend = Geom::PolygonMesh.new
            mesh_legend.add_point(meshVertices[segNum * 2])
            mesh_legend.add_point(meshVertices[segNum * 2 + 1])
            mesh_legend.add_point(meshVertices[segNum * 2 + 2])
            mesh_legend.add_point(meshVertices[segNum * 2 + 3])
            mesh_legend.add_polygon(0 + 1, 1 + 1, 3 + 1, 2 + 1)
            smooth_flags = Geom::PolygonMesh::NO_SMOOTH_OR_HIDE
            material = Sp.set_material("legend_#{segNum + 1}", colors[segNum])
            group.entities.add_faces_from_mesh(mesh_legend, smooth_flags, material)
          end

          textPt << Sp.m_point(meshVertices[-1].x + textSize * 0.5, meshVertices[-1].y, meshVertices[-1].z)

          # group.entities.add_faces_from_mesh(my_mesh)
          textPt
        end

        contourLegend ||= false
        lowB, highB, numOfSeg, legendTitle, legendBasePoint, legendScale, font,
            textSize, fontBold, decimalPlaces, greaterLessThan, contourLegend =
            [:lowB, :highB, :numSeg, :legendTitle, :legendBasePoint, :legendScale, :legendFont,
             :legendFontSize, :legendBold, :decimalPlaces, :removeLessThan].map { |key| legendPar[key] }
        legendScale ||= 1; textSize ||= nil; font ||= nil; textSize ||= nil; fontBold ||= false
        decimalPlaces ||= 2; greaterLessThan ||= false; contourLegend ||= false

        numOfSeg = numOfSeg.to_i if numOfSeg
        highB = results.max if highB == 'max'
        lowB = results.min if lowB == 'min'
        basePt = legendBasePoint.nil? ? boundingBoxP.min : legendBasePoint

        if boundingBoxP
          bbylength = boundingBoxP.max.y - boundingBoxP.min.y
          maxBoundingValue = get_maxBoundingValue(boundingBoxP)
          bbylength = maxBoundingValue.to_i if bbylength < 1
        else
          bbylength = 10.0.m
        end
        font = 'Verdana' unless font
        legendHeight = legendWidth = (bbylength / 10) * legendScale
        textSize = (legendHeight / 3) * legendScale unless textSize
        decimalPlaces = 2 unless decimalPlaces
        # Modify【2021-06-30 23:58:40】【frange_pop变成frange】
        numbers = Sp.frange(lowB, highB, Sp.round((highB - lowB) / (numOfSeg - 1), 6))
        if numbers.size == 1
          numbers; numOfSeg = 1
        elsif numbers.size < numOfSeg
          numbers << highB
        elsif numbers.size > numOfSeg
          numbers = numbers[0...-1]
        end
        formatString = "%." + decimalPlaces.to_s + "f"
        numbersStr = numbers.map { |x| formatString % x }
        if numOfSeg == 1
          numbersStr[0] = "=" + numbersStr[0]
        else
          unless greaterLessThan
            numbersStr[0] = "<=" + numbersStr[0]
            numbersStr[-1] = ">" + numbersStr[-1]
          end
        end
        # end

        numbersStr << legendTitle
        numbers << legendTitle
        # todo 可去
        # Modify【2021-12-18 01:04:36】【】
        if numOfSeg < numbersStr.size - 1
          numOfSeg += 1
        end

        # legendColors = Visualization.gradientColor(numbers[0...-1], legendPar[:lowB], legendPar[:highB], colors)
        # mesh surfaces and legend text
        textPt = legend(group, basePt, legendHeight, legendWidth, numOfSeg, textSize, color_mode, lowB, highB)
        numbersCrv = text2face(numbersStr, textPt, font, textSize, fontBold, group)

        [numbers, numbersCrv, textPt, textSize]

      end

      def self.colorMesh(colors, meshList, meshStruct = 0)


      end

      def self.gradientColor(values, lowB, highB, colors, lowBoundColor = nil, highBoundColor = nil)
        copyColors = colors
        highB = values.max if highB == 'max'
        lowB = values.min if lowB == 'min'

        # this function inputs values, and custom colors and outputs gradient colors
        def self.parNum(num, lowB, highB)
          # his function normalizes all the values
          numP =
              if num > highB
                1
              elsif num < lowB
                0
              elsif highB == lowB
                0
              else
                (num - lowB) / (highB - lowB)
              end
        end

        def self.calColor(valueP, rangeMinP, rangeMaxP, minColor, maxColor)
          # range is between 0 and 1
          rangeP = rangeMaxP - rangeMinP
          red = Sp.round(((valueP - rangeMinP) / rangeP) * (maxColor[0] - minColor[0]) + minColor[0], 0)
          blue = Sp.round(((valueP - rangeMinP) / rangeP) * (maxColor[2] - minColor[2]) + minColor[2], 0)
          green = Sp.round(((valueP - rangeMinP) / rangeP) * (maxColor[1] - minColor[1]) + minColor[1], 0)
          color = Sp.m_color(red, green, blue)
        end

        copyColors.pop unless (highBoundColor.nil?)
        copyColors.pop unless (lowBoundColor.nil?)

        numofColors = colors.size
        colorBounds = Sp.frange_pop(0, 1, Sp.round(1.0 / (numofColors - 1.0), 6))
        colorBounds << 1 if colorBounds.size != numofColors
        colorBounds = colorBounds.map { |x| Sp.round(x, 3) }
        numP = []
        values.each { |num| numP << parNum(num, lowB, highB) }

        colorTemp = []

        numP.each do |num|
          (0...numofColors).each { |i|
            if colorBounds[i] <= num && num <= colorBounds[i + 1]
              if (num == 1) && !(highBoundColor.nil?)
                colorTemp << highBoundColor; break
              elsif (num == 0) && !(lowBoundColor.nil?)
                colorTemp << lowBoundColor; break
              else
                colorTemp << (calColor(num, colorBounds[i], colorBounds[i + 1], colors[i], colors[i + 1])); break
              end
            end
          }
        end
        color = colorTemp
      end


      def self.get_maxBoundingValue(boundingBoxP)
        maxBoundingValue = [:x, :y, :z].map { |method|
          pt_max = boundingBoxP.max
          pt_min = boundingBoxP.min
          pt_max.send(method) - pt_min.send(method)
        }.max
      end

      def self.render_face_by_pos4material(face, pos4material, matrix_rgb,delete_file = true)
        Sp.make_bmp_folder_temp_block(delete_file) { |fpath|
          model = Sketchup.active_model
          mats = model.materials
          # Purpose: 【绘制图片并存取图片】
          Visualization.make_bmp_save_set(fpath, face, mats, matrix_rgb, pos4material)
        }
      end

      def self.render_face_by_pos4material_with_image(face, matrix_rgb, token)
        file, mat_name = nil
        Sp.make_bmp_folder_temp_block(false) { |fpath|
          model = Sketchup.active_model
          mats = model.materials
          # Purpose: 【绘制图片并存取图片】
          file, mat_name = Visualization.make_bmp(face, fpath, matrix_rgb) { |face| token }
        }
        [file, mat_name]
      end


      def self.render_face_by_info_face2d(face, info_face2d, matrix_rgb)
        Sp.make_bmp_folder_temp_block { |fpath|
          model = Sketchup.active_model
          mats = model.materials

          pos4material = make_pos4material(*[:pt_origin_of_face, :step_uv, :uv_max_face2d,
                                             :uv_min_face2d, :vector_xaxis_of_face, :vector_yaxis_of_face
          ].map { |key| info_face2d[key] })

          # Purpose: 【绘制图片并存取图片】
          Visualization.make_bmp_save_set(fpath, face, mats, matrix_rgb, pos4material)
        }
      end

      def self.make_bmp_save_set(path_temp, face, mats, rgb_matrix, pos4material)
        # Purpose: 【绘制图片并模糊】
        file, mat_name = make_bmp(face, path_temp, rgb_matrix)

        # Purpose: 【制造材质，将存取的图片赋予材质，贴于面上】
        matl = mats.add(mat_name)
        matl.texture = file
        face.position_material(matl, pos4material, true)
        # Tips：【pos4material 必须包含 2、4、6 或 8 个点。这些点成对使用，
        # 以指示纹理图像中的点在面部上的位置。每对中的第一个点是
        # 模型中的一个3D点。它应该是面部的一个点;
        # 每对点中的第二个点是一个2D点(x=?,y=?,z=0),它给出图像中一个点的 (u,v) 坐标以与 3D 点匹配。】
      end

      def self.valL2rgbL(color_mode, valL)
        max_val, min_val = [valL.max, valL.min]
        range_val = max_val - min_val
        rgbL = valL.map { |val|
          val_normal = (range_val != 0) ? (val - min_val) / range_val : 0.5
          Visualization.rgb(val_normal, color_mode)
        }
      end

      def self.val_matrix2rgb_matrix_2(color_mode, mrt_matrix)
        vals_mrt = mrt_matrix.flatten.flatten
        max_val, min_val = block_given? ? yield() : [vals_mrt.max, vals_mrt.min]
        range_val = max_val - min_val
        rgb_matrix = []

        exception_counter = 0  # 异常值计数器

        mrt_matrix.each_with_index do |mrt_row, row_idx|
          rgb_row = []

          mrt_row.each_with_index { |mrt, col_idx|
            if range_val != 0
              mrt_normal = (mrt - min_val) / range_val
              mrt_normal = 1 if mrt_normal > 1
              mrt_normal = 0 if mrt_normal < 0
            else
              mrt_normal = 0.5
            end

            rgb = Visualization.rgb(mrt_normal, color_mode)

            rgb_row << rgb
          }

          rgb_matrix << rgb_row
        end
        rgb_matrix
      end



      def self.val_matrix2rgb_matrix(color_mode, mrt_matrix,flag70 = false)
        vals_mrt = mrt_matrix.flatten.flatten
        max_val, min_val = block_given? ? yield() : [vals_mrt.max, vals_mrt.min]
        range_val = max_val - min_val
        rgb_matrix = []
        if flag70
          min_val = 0
          range_val = 70
        end
        mrt_matrix.each do |mrt_row|
          rgb_row = []
          mrt_row.each { |mrt|
            if range_val != 0
              mrt_normal = (mrt - min_val) / range_val
            else
              mrt_normal = 0.5
            end
            rgb_row << Visualization.rgb(mrt_normal, color_mode) }
          rgb_matrix << rgb_row
        end
        rgb_matrix
      end

      def self.rgb(num, meth)
        num = 0 if num.nil?
        if meth == COLOR_MODE_GREY
          r, g, b = [(255 * num).to_i] * 3
        elsif meth == COLOR_MODE_BRY
          if num < 0.1
            r, g, b = [0, 0, 255]
          else
            r, g, b = [(255 * (2 * num)).to_i, (255 * (2 * num - 1)).to_i, (255 * (1 - num)).to_i]
            r, g, b = [r, g, b].map { |r_or_g_b|
              r_or_g_b = 0 if r_or_g_b < 0
              r_or_g_b = 255 if r_or_g_b > 255
              r_or_g_b
            }
          end
        elsif meth == COLOR_MODE_RAINBOW
          # https://www.krishnamani.in/color-codes-for-rainbow-vibgyor-colours/
          level1 = 1.0 / 6.0
          level3 = 1.0 / 6.0 * 2.0
          level4 = 0.5
          level5 = 1.0 / 6.0 * 4.0
          if num <= level3
            r = 148.0 - 148.0 / level3 * num
            g = 0.0
            b = 211.0 + (255.0 - 211.0) / level3 * num
          elsif num > level5
            r = 255.0
            g = 255.0 - 255.0 / level3 * (num - level5)
            b = 0.0
          elsif num > level3 && num <= level4
            r = 0.0
            g = 255.0 * (num - level3) / level1
            b = 255.0 - 255.0 * (num - level3) / level1
          elsif num < level5 && num > level4
            r = 255.0 * (num - level4) / level1
            g = 255.0
            b = 0
          else
            r, g, b = [0.0, 255.0, 0.0]
          end
          r, g, b = [r, g, b].map { |x| x.to_i }
        elsif meth == COLOR_MODE_BYR
          level1 = 0.25
          level2 = 0.5
          if num <= level1
            r = 0.0
            g = 255.0 * num / level1
            b = 255.0 - 255.0 * num / level1
          elsif num > level1 && num <= level2
            r = 255.0 * (num - level1) / level1
            g = 255.0
            b = 0.0
          elsif num > level2
            r = 255.0
            g = 255.0 - 255.0 * (num - level2) / level2
            b = 0.0
          else
            r, g, b = [255.0, 255.0, 0.0]
          end
          r, g, b = [r, g, b].map { |x| x.to_i }
        else
          r, g, b = [0, 0, 0]
        end # if meth
        [r, g, b]
      end

      def self.text2face(text, pt_text, font = 'Verdana', height_text = 20, bold = false, grp_parent = nil, plane = nil, idx_justification = 0)

        def self.reserve_negtive_faces(ents_sub)
          all_ents = ents_sub.to_a
          to_reserve_faces = all_ents.select { |ent| next unless ent.is_a?(Sketchup::Face); negtive_face?(ent) }
          to_reserve = to_reserve_faces.map { |f| f.edges }.flatten! + to_reserve_faces
          to_erase = all_ents - to_reserve
          ents_sub.erase_entities(to_erase)
        end

        faces_text = []
        grp_text = gen_grp_or_by_grp(grp_parent)
        ents_text = grp_text.entities
        text_justification = text_justification_enumeration(idx_justification)

        text.each_index do |i|
          grp_sub = ents_text.add_group
          ents_sub = grp_sub.entities

          vec_tr = ORIGIN.vector_to(pt_text[i])
          grp_sub.transform!(vec_tr)

          res = ents_sub.add_3d_text(text[i], text_justification, font,
                                     bold, false, height_text, 0.0, 0.0, true, 1.0)
          reserve_negtive_faces(ents_sub)
          faces_text << reverse_faces(ents_sub)
          grp_sub.explode
        end
        faces_text.flatten!

        [faces_text, grp_text]
      end

      def self.calculate_bb(geoms_or_geom, restricted = false)
        bb = Geom::BoundingBox.new

        if geoms_or_geom
          geo_flatten = []
          if geoms_or_geom.is_a?(Array)
            geoms_or_geom.each { |g| geo_flatten << g }
          else
            geo_flatten << geoms_or_geom
          end
          ents_all = geo_flatten.flatten!
          pts_all = []
          ents_all.each do |ent|
            (pts_all << ent; next) if ent.is_a?(Geom::Point3d)
            if ent.respond_to?(:vertices)
              ent.vertices.map(&:position).each { |pt| pts_all << pt }
            end

          end
          bb.add(pts_all)
        end

        {:minZPt => bb.corner(1),
         :maxZPt => bb.corner(5),
         :titleBasePt => bb.corner(0),
         :BBXlength => bb.corner(0).distance(bb.corner(1)),
         :BBYlength => bb.corner(0).distance(bb.corner(2)),
         :BBZlength => bb.corner(0).distance(bb.corner(4)),
         :CENTERPoint => m_cpt(bb.corner(1), bb.corner(6))
        }

      end


      def self.get_pt_sphere_sun(scale_sun, pt_sun, projection, cenpt, scale, grp_parent = nil)
        grp_sun = gen_grp_or_by_grp(grp_parent)
        ents_sun = grp_sun.entities
        radius = 3 * scale_sun
        if [1, 2].include?(projection)
          pt_sun = project_geo([pt_sun], projection, cenpt, scale)[0]
          sphere_sun = ents_sun.add_circle(pt_sun, Z_AXIS, radius)
        else
          m_sphere(ents_sun, pt_sun, radius)
        end
        face_sphere_sun = ents_sun.grep(Sketchup::Face)
        [grp_sun, pt_sun]
      end

      def self.color_faces(colors, faces)
        faces.each_with_index { |f, i| set_face_material(f, i.to_s, colors[i], 255) }
        faces
      end

      def self.make_gradient_color(values, lowb, highb, colors, color_low_bound = nil, color_high_bound = nil)

        def self.get_num_par(num, lowb, highb)
          nump =
              if num > highb
                1
              elsif num < lowb
                0
              elsif highb == lowb
                0
              else
                (num - lowb) / (highb - lowb)
              end
        end

        def self.cal_color(valuep, range_min_p, range_max_p, min_color, max_color)
          range_p = range_max_p - range_min_p
          red = (((valuep - range_min_p) / range_p) * (max_color.red - min_color.red) + min_color.red).round
          blue = (((valuep - range_min_p) / range_p) * (max_color.blue - min_color.blue) + min_color.blue).round
          green = (((valuep - range_min_p) / range_p) * (max_color.green - min_color.green) + min_color.green).round
          m_color(red, green, blue)
        end


        colors_copy = colors.dup
        highb = max(values) if highb == 'max'
        lowb = max(values) if lowb == 'min'

        colors_copy.pop! if color_high_bound
        colors_copy.pop! if color_low_bound
        num_of_colors = colors.size


        colors_bounds = frange(0, 1, (1 / (num_of_colors - 1).round(6)))
        colors_bounds << 1 if colors_bounds.size != num_of_colors
        colors_bounds = colors_bounds.map { |x| x.round(3) }
        num_par = []
        values.each_index { |i| num_par << get_num_par(i, lowb, highb) }

        color = []

        num_par.each do |num|
          num2list(num_of_colors).each { |i|
            next unless (colors_bounds[i] <= num && colors_bounds[i + 1] >= num)
            (color << color_high_bound; break) if num == 1 && !color_high_bound.nil?
            (color << color_low_bound; break) if num == 0 && !color_low_bound.nil?
            color << cal_color(num, colors_bounds[i], colors_bounds[i + 1], colors[i], colors[i + 1])
            break
          }
        end
        color

      end

      def self.make_circle_compass(grp_parent = nil, cenpt = ORIGIN, vec_north = Y_AXIS, radius = 200, angles = frange(0, 260, 30), line_center = false)

        def self.draw_line(ents, cenpt, vector, radius, line_main = false, x_move = 5, line_center)
          st_pt_ratio = 1
          ed_pt_ratio = 1.08
          text_pt_ratio = ed_pt_ratio + 0.08
          (ed_pt_ratio = 1.15; text_pt_ratio = 1.17) if line_main
          st_pt = line_center ? cenpt : cenpt.transform(vec_mul_length(vector.clone, st_pt_ratio * radius))
          ed_pt = cenpt.transform(vec_mul_length(vector.clone, ed_pt_ratio * radius))
          pt_text_base = cenpt.transform(vec_mul_length(vector.clone, text_pt_ratio * radius))
          pt_text_base =
              if line_main
                m_point(pt_text_base.x - (x_move / 2), pt_text_base.y - (x_move / 2), pt_text_base.z)
              else
                m_point(pt_text_base.x - x_move, pt_text_base.y - (x_move / 4), pt_text_base.z)
              end
          ents.add_line(st_pt, ed_pt)
          [[st_pt, ed_pt], pt_text_base]
        end

        grp_lines = gen_grp_or_by_grp(grp_parent)
        ents_line = grp_lines.entities

        grp_compass = gen_grp_or_by_grp(grp_parent)
        ents_compass = grp_compass.entities

        circle_base = ents_compass.add_circle(cenpt, Z_AXIS, radius, 48)
        circle_outer = ents_compass.add_circle(cenpt, Z_AXIS, radius * 1.02, 48)
        x_move = 0.3 * radius

        lines = []; pts_base_text = []
        angles_main = [0, 90, 180, 270]
        text_main = ['N', 'E', 'S', 'W']
        text_alt1 = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
        text_alt2 = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']
        text_compass = []

        angles.each do |angle|
          line_main = false
          line_main = true if angles_main.include?(angle)
          vector = vec_north.clone
          vector = vector.transform(m_rotate(ORIGIN, Z_AXIS, -angle.degrees))
          line, pt_base = draw_line(ents_compass, cenpt, vector, radius, x_move, line_center)

          if angles.size != 8 && angles.size != 16
            if line_main
              text_compass << text_main[angles_main.index(angle)]
            else
              text_compass << angle.to_i.to_s
            end
          end

          pts_base_text << pt_base
          lines << line
        end

        if angles.size == 8
          text_compass = text_alt1
        elsif angles.size == 16
          text_compass = text_alt2
        end

        lines << circle_base
        lines << circle_outer
        [grp_compass, pts_base_text, text_compass]


      end

      # Internal: List all points in entities.
      #
      # entities - An Entities object, and Entity or an array of these.
      #
      # Returns Array of Points3d objects.
      def self.points_in_entities(entities)

        # Make entities an array of drawing elements.
        entities = entities.to_a if entities.is_a?(Sketchup::Entities)
        entities = [entities] if entities.is_a?(Sketchup::Drawingelement)

        recursive = lambda do |ents|
          pts = []
          ents.each do |e|
            if e.respond_to? :vertices
              pts += e.vertices.map { |v| v.position }
            elsif e.respond_to?(:definition)
              t = e.transformation
              pts += recursive.call(e.definition.entities).map { |p| p.transform t }

            end
          end
          pts
        end

        pts = recursive.call entities
        pts.uniq! { |a| a.to_a }
        pts

      end

      def self.text_justification_enumeration(idx_justification)
        #justificationIndices:
        # 0 - TextAlignLeft,
        # 1 - TextAlignRight
        # 2 - TextAlignCenter
        constantsList = [TextAlignLeft, TextAlignRight, TextAlignCenter]
        text_justification = constantsList[idx_justification]
      end

      #Draw a text in a view (with correction of Y for Mac)
      def self.view_draw_text(view, pt, text)
        pt = view.screen_coords(pt.clone)
        pt.y += 3
        pt.x += 3
        hsh = {:font => 'Verdana', :size => 10, :bold => true}
        view.draw_text pt, text, hsh
      end

      private

      def self.make_bmp(face, path_temp, rgb_matrix)
        bitmap = Bitmap.new(rgb_matrix)
        bitmap.blur(0)

        # Purpose: 【存储图片】
        bitmap.path = path_temp
        mat_name = block_given? ? yield(face) : face.object_id.to_s; file = mat_name + '.bmp'
        bitmap.write(file)
        return file, mat_name
      end


    end
  end
end
    