require 'json'
module SuperCat
  module Sunpath
    class SunpathSectionTool
      include Window

      def initialize

        @xdown = 0
        @ydown = 0
        @path = []
        reset
        # info_shadow = Hash[['City', 'Country', 'DayOfYear', 'Latitude', 'Longitude', 'North'].map { |item| [item, []] }]

      end

      def activate
        @ip = Sketchup::InputPoint.new
        @window ||= create_window
        show_dlg(@window) { init_window }
        Sketchup.active_model.active_view.invalidate
      end

      def deactivate(view)
        destroy_dlg(@window)
        view.invalidate
      end

      def onKeyDown(key, repeat, flags, view)

        flag = false
        return unless @path.size == 1
        cenpt = @path[0]
        if key == VK_UP
          cenpt.y = cenpt.y + 0.05.m
          flag = true
        elsif key == VK_DOWN
          cenpt.y = cenpt.y - 0.05.m
          flag = true
        elsif key == VK_LEFT
          cenpt.x = cenpt.x - 0.05.m
          flag = true
        elsif key == VK_RIGHT
          cenpt.x = cenpt.x + 0.05.m
          flag = true
        elsif key == 104 # 小键盘8
          cenpt.z = cenpt.z + 0.2.m
          flag = true
        elsif key == 98 # 小键盘2
          cenpt.z = cenpt.z - 0.2.m
          flag = true
        end

        if flag
          @path = [cenpt]
          update_scene
        end

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
        @time_zone = 8
        @month = info_time_now[:month]
        @day = info_time_now[:day]
        @hour = 12
        @scale_sun_path = 5
        @lat = info_time_shadow['Latitude'] || 23.12
        @lon = info_time_shadow['Longitude'] || 113.30
        @city = info_time_shadow['City'] || '广州'
        set_location_shadow(@city, @lon, @lat)
        # info_shadow['DisplayShadows'] = true
        @north = 0
      end

      def onMouseMove(flags, x, y, view)
        @ip.pick view, x, y
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        @path = [ip2pt(@ip)]
        model = Sketchup.active_model
        shadow_info = model.shadow_info
      end

      def draw(view)
        @ip.draw(view)
        view.line_width = 3
        view.draw_points([ip2pt(@ip)], 10, 4, OPT_PREVIEW_COLOR)
        view.draw_points(@path, 10, 4, OPT_SELECTED_COLOR) if @path.size > 0
        # view.invalidate
      end

      private

      def ip2pt(ip)
        ip.position
      end


      def create_window
        window = UI::HtmlDialog.new(OPTION_HTMLDLG)
        html_file = HTML_DIALOG_SUNPATHSECTION
        window.set_file(html_file)
        #SunPathWindow.new
        #
        window.add_action_callback("update_scene") {
          Sunpath.operation('更新场景') { update_scene }
        }

        window.add_action_callback("time_step_month") { |dialog, token|
          data = token2data(token)
          @month = data[0]
          Sketchup.active_model.active_view.invalidate
        }

        window.add_action_callback("domeSizeChange") { |dialog, token|
          data = token2data(token, :to_f)
          @scale_sun_path = Sp.nil_or_set(data[0], :to_f)
          Sketchup.active_model.active_view.invalidate
        }

        window.add_action_callback("callback_time") { |dialog, token|
          data = token2data(token)
          @month = data[0]
          @day = data[1]
          # p "month: #{@month}, day: #{@day}"
          update_scene
          set_shadow_vector
          Sketchup.active_model.active_view.invalidate
        }

        callback_dlg(window, "submit_location") { |data|
          info = data[0]
          @index = info['index']
          @city = info['city']
          p "city: #{@city}, longitude: #{@lon}, latitude: #{@lat}, time zone: #{@time_zone}"
          @lon = Sp.nil_or_set(info['lon'], :to_f)
          @time_zone = Sp.nil_or_set(info['timezone'], :to_i) || 8
          @lat = Sp.nil_or_set(info['lat'], :to_f)
        }

        window.set_on_closed { window = nil }

        window
      end

      def update_scene
        # info_time = Sp.fatch_shadow_time
        set_location_shadow(@city, @lon, @lat)
        @grp_sp.erase! if @grp_sp && !@grp_sp.deleted?
        info_grps = SunPath.creat_sunpath_section(
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
        # refresh_azm_alt(info_grps[:azm_sum], info_grps[:alt_sun])
      end

      # def refresh_azm_alt(azms_sum, alts_sun)
      #   @window.execute_script("setSunAzimuth(#{azms_sum[0].round(2)})") if azms_sum && azms_sum != []
      #   @window.execute_script("setSunAlitude(#{alts_sun[0].round(2)})") if alts_sun && alts_sun != []
      # end


      def init_window
        init_window_remove_excess
        init_window_time
        @window.execute_script('vm_dome_scale.scale=5')
        init_window_library
      end

      def init_window_remove_excess
        @window.execute_script("ss.remove_excess()")
      end

      def init_window_time
        info_time_now = Sp.fetch_time_now
        @window.execute_script("ss.gen_time_step()")
        @window.execute_script("ss.vm_time_setting.selectTimeStateMonth(#{info_time_now[:month]})")
        @window.execute_script("ss.vm_time_setting.selectTimeStateDay(#{info_time_now[:day]})")
      end

      def init_window_library
        file_content = File.read(LOCATION_CITIES_PATH)
        database = JSON.parse(file_content)
        database = database.map { |city|
          city.to_json #JSON.parse(city.to_s)
        }
        @window.execute_script("sp.initLibrary(#{database})")
      end


      def set_shadow_vector()
        info_time_now = Sp.fetch_time_now
        info_shadow_time = {:year => info_time_now[:year],
                            :month => @month,
                            :day => @day,
                            :hour => @hour,
                            :minute => info_time_now[:minute],
                            :second => info_time_now[:second]
        }
        set_time_shadow(info_shadow_time, @time_zone)
      end

      def set_time_shadow(info_shadow_time, time_zone)
        time = Sp.info_time2time(info_shadow_time, time_zone)
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        shadow_info["ShadowTime"] = time
        Sketchup.active_model.shadow_info['Dark'] = 30
        Sketchup.active_model.shadow_info['Light'] = 70
        # p "shadow_info= " + shadow_info.to_a.to_s + "【rzw_Sunpath/tool/sun_path_tool.rb:251】"
      end

      def set_location_shadow(city, lon, lat, timezone = 8)
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        shadow_info['City'] = city
        shadow_info['Longitude'] = lon
        shadow_info['Latitude'] = lat
        shadow_info['TZOffset'] = timezone # 不应该设置时区偏移，因为SU里面的时间已经是本初子午线的时间
      end




    end
  end
end
