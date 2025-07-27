module SuperCat
  module Sunpath

    class Sp
      require 'securerandom'

      DIR_PREV ||= Dir.getwd

      private

      def intdiv(a, b)
        (a.to_f / b.to_f).round # ruby整数除法是向负无穷舍入
      end

      def self.path_cmd2path_token(path, token)
        dir = File.dirname(path)
        file = File.split(path)[-1]
        file_new = file.gsub(/_infoToCpp.json/, '_' + token)
        path_new = File.join(dir, file_new)
      end

      def self.path_cmd2path_token2(path, token)
        dir = File.dirname(path)
        file = File.split(path)[-1]
        path_new = File.join(dir, token)
      end

      def self.color(a, b, c, d = 0)
        Sketchup::Color.new(a, b, c, d)
      end

      def self.randomArray(arr)
        newArr = []
        arr.count.times do
          index = arr.count
          newArr << arr[rand(index)]
          arr = arr - newArr
        end
        newArr
      end

      def self.cal_rgbL(denominator = 20, alpha = 10)
        colorL = []
        (0...255).each do |r|
          next unless r % denominator == 0
          (0...255).each do |g|
            next unless g % denominator == 0
            (0...255).each do |b|
              next unless b % denominator == 0
              colorL << color(r, g, b, alpha)
            end
          end
        end
        randomArray(colorL)
      end


      def self.rgb(num, meth)
        if meth == 0
          color(num, 255 - num, (255 - num / 2).to_i, 255)
        elsif meth == 1
          color(num, num, num, 255)
        else
          colorsSU = Sketchup::Color.names
          n = num % colorsSU.size
          colorsSU[n]
        end # if meth
        #
        #
      end


      def self.deep_clone(self_)
        Marshal::load(Marshal.dump(self_))
      end

      def self.generate_uuid(self_)
        loop do
          token = SecureRandom.uuid
          break token unless self_.instance_variable_get("@id") == token
        end
      end

      def self.m_cpt_of_facet(facet)
        vf = facet.vertices
        c0 = vf[0].position
        c2 = vf[2].position
        cpt_facet = Sp.m_cpt(c0, c2)
      end

      def self.m_cpt_of_triangle(ptL)
        return false if ptL.size != 3
        c0, c1, c2 = ptL
        Sp.m_point(
            (c0.x + c1.x + c2.x) / 3.0,
            (c0.y + c1.y + c2.y) / 3.0,
            (c0.z + c1.z + c2.z) / 3.0
        )
      end

      def self.lengthPt(a)
        Math.sqrt(a.dot(a))
      end

      def self.areaPts(a, b, c)
        lengthPt(((b - a).cross(c - a)))
      end

      def self.m_cpt_of_face(face, tr)
        ptL = face.vertices.map(&:position)
        return false if ptL.size < 3
        x_sum, y_sum, z_sum = [0.0, 0.0, 0.0]
        area_sum = 0.0
        ptL.each_with_index do |pt, ipt|
          next if ipt < 2
          ptsTri = [ptL[0], ptL[ipt - 1], ptL[ipt]]
          cpt = m_cpt_of_triangle(ptsTri)
          return false unless cpt
          weight = areaPts(*ptsTri)
          area_sum += weight
          x_sum += cpt.x * weight
          y_sum += cpt.y * weight
          z_sum += cpt.z * weight
        end
        m_point(x_sum / area_sum, y_sum / area_sum, z_sum / area_sum).transform(tr)
      end

      # Internal: Find arbitrary point inside face, not on its edge or corner.
      #
      # face - The face to find a point in.
      #
      # Returns a Point3d object.
      def self.point_in_face_x(face, coef = 0.99)

        # Sometimes invalid faces gets created when intersecting.
        # These are removed when validity check run.
        return false if face.area == 0

        # Find points by combining 3 adjacent corners.
        # If middle corner is convex point should be inside face (or in a hole).
        face.vertices.each_with_index do |v, i|
          c0 = v.position
          c1 = face.vertices[i - 1].position
          c2 = face.vertices[i - 2].position
          p = Geom.linear_combination coef, c0, (1 - coef), c2
          p = Geom.linear_combination coef, p, (1 - coef), c1

          cp = face.classify_point(p)
          #face.parent.entities.add_cpoint p
          return p if cp == Sketchup::Face::PointInside
        end

        #puts "Could not find any point within face :( ."

        # This line should never be reached.
        # If it does code isn't functioning as intended :( .
        false

      end

      def self.round(number, ndigit)
        (number * 10 ** ndigit).round.to_f / 10 ** ndigit
      end

      def self.face2pts_outer(face, tr)
        loops_f = face.outer_loop
        pts_outer = loops_f ? loops_f.vertices.map { |v| v.position.transform(tr) } : nil
        return pts_outer
      end

      def self.face2pts_outer_inner(face, tr)
        loops_f = face.loops
        return [nil, nil] unless loops_f
        # Purpose: 【目前只支持有一个洞】
        loops_outer, loops_inner = loops_f.partition { |loop_f| loop_f.outer? }.map(&:first)
        pts_outer = loops_outer ? loops_outer.vertices.map { |v| v.position.transform(tr) } : nil
        pts_inner = loops_inner ? loops_inner.vertices.map { |v| v.position.transform(tr) } : nil
        return pts_inner, pts_outer
      end

      def self.face2pts_outer_inners(face, tr)
        loops_f = face.loops
        return [nil, nil] unless loops_f
        # Purpose: 【目前只支持有一个洞】
        loops_outer, loops_inner = loops_f.partition { |loop_f| loop_f.outer? }
        pts_outer = loops_outer ? loops_outer[0].vertices.map { |v| v.position.transform(tr) } : nil
        pts_inners =
            if loops_inner
              loops_inner.map { |loop_inner| loop_inner.vertices.map { |v| v.position.transform(tr) } }
            else
              nil
            end
        return pts_inners, pts_outer
      end

      def self.get_name_of_current_skp()
        model = Sketchup.active_model
        model_path = model.path # 返回模型保存的位置,若为新模型则返回''
        if model_path == ''
          p '尚未保存模型'
          ''
        else
          File.basename(model_path, ".skp")
        end
      end

      def self.make_path_temp(token)
        model = Sketchup.active_model
        model_path = model.path # 返回模型保存的位置,若为新模型则返回''
        if model_path == ''
          home = ENV['HOME'] || ENV['USERPROFILE']
          Dir.chdir(home) #  Dir当前所在的目录改变为home
          folder = '_temp_simple_rays'
          Dir.mkdir(folder) unless Kernel.test(?d, folder) #  d for directory
          Dir.chdir(folder)
          path = Dir.getwd #  返回Dir当前所在的目录
          folder = model.guid << '_' + token
        else
          folder = File.basename(model_path, ".skp") + '_' + token
          path = File.dirname(model_path)
          Dir.chdir(path)
        end
        path = Pathname.new(path).cleanpath.to_s
        Dir.mkdir(folder) unless Kernel.test(?d, folder) # was: if Dir[folder] == []
        Dir.chdir(folder)
        path_temp = File.join(path, folder)
        [path_temp, folder]
      end

      def self.make_bmp_folder_temp_block(delete_fold = true) # |fpath|

        folder, path = make_bmp_folder
        Dir.mkdir(folder) unless Kernel.test(?d, folder)
        Dir.chdir(folder)

        begin
          yield(File.join(path, folder))
        rescue => e
          raise
        ensure
          return unless delete_fold
          fpath = File.join(path, folder)
          Dir.chdir(fpath) if Dir.getwd != fpath
          Dir.glob("*.{bmp}") { |file| File.delete(file) if Kernel.test(?f, file) }
          if Dir[].empty? # avoid a SystemCallError
            Dir.chdir("..")
            Dir.rmdir(folder) if Kernel.test(?d, folder)
          end
          Dir.chdir(DIR_PREV) # restore the previous Dir
        end

      end

      def self.make_bmp_folder
        model = Sketchup.active_model
        model_path = model.path # 返回模型保存的位置,若为新模型则返回''
        if model_path == ''
          home = ENV['HOME'] || ENV['USERPROFILE']
          Dir.chdir(home) #  Dir当前所在的目录改变为home
          folder = '_temp_simple_rays'
          Dir.mkdir(folder) unless Kernel.test(?d, folder) #  d for directory
          Dir.chdir(folder)
          path = Dir.getwd #  返回Dir当前所在的目录
          folder = model.guid << '-images'
        else
          folder = File.basename(model_path, ".skp") + '_images'
          path = File.dirname(model_path)
          Dir.chdir(path)
        end
        return folder, path
      end


      def self.draw_rays(rays, length = 10)
        ent = Sp.gen_group.entities
        rays.each do |ray|
          Sp.draw_ray(ray, length, ent)
        end
      end

      def self.draw_ray(ray, length = 10, ent = nil)
        pt1, vec = ray
        vec = Geom::Vector3d.new(vec)
        vec.length = length
        pt2 = pt1 + vec
        ent ||= Sketchup.active_model.active_entities
        ent.add_line(pt1, pt2)
      end

      def self.get_the_top_model
        model = Sketchup.active_model.active_path.first.parent
      end

      def self.sum(arr)
        arr.inject(0, :+)
      end

      def self.roll_arr(arr, index_start_new_arr)
        if index_start_new_arr != 0
          return (arr[index_start_new_arr..-1] + arr[0...index_start_new_arr])
        else
          return arr
        end
      end

      def self.entities_from_group_or_componet(group_or_component)
        return group_or_component.entities if group_or_component.is_a?(Sketchup::Group)
        group_or_component.definition.entities
      end

      def self.fetch_first_sth_from_grp(grp, type)
        ents = grp.entities
        ents.find { |ent| ent.is_a?(type) }
      end

      def self.is_a_grpcp?(grpcp)
        grpcp.is_a?(Sketchup::Group) || grpcp.is_a?(Sketchup::ComponentInstance)
      end


      def self.fetch_faces_from_grpcp(grp_or_cp)
        return unless (ents = entities_from_group_or_componet(grp_or_cp))
        ents.grep(Sketchup::Face)
      end

      def self.fetch_first_face_from_grpcp(grp_or_cp)
        return unless (ents = entities_from_group_or_componet(grp_or_cp))
        ents.find { |ent| ent.is_a?(Sketchup::Face) }
      end

      def self.grpcpHaveGround?(grpcps)
        # 地面是一个组，组中的所有面的rzw_prototool_house3d_gen字典的 类型属性都是Ground）
        grpcps.any? { |grpcp|
          face = self.fetch_first_face_from_grpcp(grpcp)
          if face
            self.fetch_attr_from_house3d_ent(face, KEY_C::CK_TYPE) == TYP_C::CV_GROUND
          else
            false
          end
        }
      end

      def self.set_grp_ref_id(grp_ref)
        guid = /(?<=Group:).*(?=>)/.match(grp_ref.to_s)
        id_grp_geometry = "#{guid}_#{Time.now.to_i}.skp"
        Sp.set_attr_to_ent(grp_ref, KEY_C::CK_ID_FACE_ANALYSIS, id_grp_geometry)
        Sp.set_attr_to_ent(grp_ref, GEO_C::CK_PTBASE, grp_ref.bounds.corner(1))
        id_grp_geometry
      end

      def self.fetch_attr_from_house3d_ent(ent, attr, default_value = nil)
        ent.get_attribute(ATTR_DICT_HOUSE3D_GEN, attr, default_value)
      end

      def self.fetch_3d_attr_from_ent(ent, attr, default_value = nil)
        ent.get_attribute(ATTR_DICT_HOUSE3D_GEN, attr, default_value)
      end

      def self.fetch_pro_abs_attr_from_ent(ent, attr, default_value = nil)
        ent.get_attribute(ATTR_DICT_PROTOTOOL_ABSTRACTION, attr, default_value)
      end

      def set_attr_to_ents(ents, attr, default_value = nil)
        ents.each { |ent| ent.set_attribute(ATTR_DICT_ABSTRACTION, attr, default_value) }
      end

      def set_attr_to_ents3D(ents, attr, default_value = nil)
        ents.each { |ent| ent.set_attribute(ATTR_DICT_PROTOTOOL_HOUSE3D, attr, default_value) }
      end

      def self.set_attr_to_ent(ent, attr, default_value = nil)
        ent.set_attribute(ATTR_DICT_ABSTRACTION, attr, default_value)
      end

      def self.set_attr_to_ent_simple(ent, attr, default_value = nil)
        ent.set_attribute(ATTR_DICT_SIMPLE, attr, default_value)
      end

      def self.fetch_attr_from_ent(ent, attr, default_value = nil)
        ent.get_attribute(ATTR_DICT_ABSTRACTION, attr, default_value)
      end

      def self.fetch_attr_from_ent_simple(ent, attr, default_value = nil)
        ent.get_attribute(ATTR_DICT_SIMPLE, attr, default_value)
      end

      def self.vec2point(vec)
        Geom::Point3d.new(vec.x, vec.y, vec.z)
      end

      def self.m_rotate(pt, axis, radians)
        Geom::Transformation.rotation(pt, axis, radians)
      end

      def self.rotate(ent, pt, axis, radians)
        rotation = m_rotate(pt, axis, radians)
        ent.transform(rotation)
      end

      def self.m_axis_radians_for_rotate_by_vec2vec(vec1, vec2)
        angleR = vec1.angle_between(vec2) # in radians
        axis = vec1.cross(vec2).normalize
        [axis, angleR]
      end

      def self.angleR_is_0PI?(angleR)
        (angleR - Math::PI).abs < 0.0001 || (angleR -0.0).abs < 0.0001
      end

      def self.m_vec(x, y, z)
        Geom::Vector3d.new(x, y, z)
      end

      def self.gen_vec_xyz
        [m_vec(1, 0, 0), m_vec(0, 1, 0), m_vec(0, 0, 1)]
      end

      def self.m_vec_by_x(x)
        Geom::Vector3d.new(x, 0, 0)
      end

      def self.m_vec_by_y(y)
        Geom::Vector3d.new(0, y, 0)
      end

      def self.m_vec_by_z(z)
        Geom::Vector3d.new(0, 0, z)
      end

      def self.m_point(x, y, z)
        Geom::Point3d.new(x, y, z)
      end

      def self.p_and_s(token)
        p token
        Sketchup.status_text = token
      end

      def self.isLeapYear(yr)
        return ((yr % 4 == 0 && yr % 100 != 0) || yr % 400 == 0)
      end

      def self.calcDayOfYear(mn, dy, year = 2022)

        if isLeapYear(year)
          k = 1
        else
          k = 2
        end
        doy = ((275 * mn) / 9).to_int - k * ((mn + 9) / 12).to_int + dy - 30;
        return doy
      end


      def self.set_grp_leftdown_pt(grp)
        minPt = grp.bounds.min
        maxPt = grp.bounds.max
        Sp.m_point(maxPt.x, minPt.y, minPt.z)
      end

      def self.gen_pts_xyz
        [m_point(1, 0, 0), m_point(0, 1, 0), m_point(0, 0, 1)]
      end

      def self.pt2vec(pt)
        m_vec(pt.x, pt.y, pt.z)
      end

      def self.calculate_timezone(lon)
        (lon / 15.0).round
      end

      def self.nil_or_set(to_get, method)
        return unless to_get
        [to_get].map(&method)[0]
      end

      def self.nil_or_default(to_get, default)
        if to_get
          to_get
        else
          default
        end
      end

      def self.vec_mul_length(vec, to_mul)
        vec.length = vec.length * to_mul
        vec
      end

      def self.hemisphere_vecL_dir(normal, numRaySqrt)

        ang_v = 90.degrees
        vecL_dir = [normal]
        vecL_angv = [ang_v]
        origin = Geom::Point3d.new(0, 0, 0)
        angle_vertical = 90.degrees / numRaySqrt - 0.01
        angle_horizontal = 360.degrees / numRaySqrt
        random_vector = [rand(100) + 1, rand(100) + 1, rand(100) + 1]
        axis = normal * random_vector
        rotate_vertical = Geom::Transformation.rotation(origin, axis, angle_vertical)
        vector = normal.transform(rotate_vertical)

        numRaySqrt.times do
          numRaySqrt.times do
            vecL_dir << vector
            rotate_horizontal = Geom::Transformation.rotation(origin, normal, angle_horizontal)
            vector = vector.transform(rotate_horizontal)
            vecL_angv << ang_v
          end
          axis = normal * vector
          rotate_vertical = Geom::Transformation.rotation(origin, axis, angle_vertical)
          ang_v -= angle_vertical
          vector = vector.transform(rotate_vertical)
        end
        #
        return [vecL_dir, vecL_angv]
        #
      end

      def self.m_circle_by_3pts(ents, pt1, pt2, pt3)
        cpt = m_cpt(m_cpt(pt2, pt1), m_cpt(pt1, pt3))
        radius = cpt.distance(pt1)
        vec01 = cpt.vector_to(pt1)
        vec02 = cpt.vector_to(pt2)
        vec_nor = vec01.cross(vec02).normalize
        ents.add_circle(cpt, vec_nor, radius, 48)
        # # v1, v2, v3 = gen_pts_xyz.map { |vec| vec.transform(vec_normal) }.map { |pt| pt2vec(pt) }
        # # p "v1 = " + v1.to_s + "【rzw_microclimate/preparation.rb:38】"
        # tr_r = Geom::Transformation.axes(pt1, *axes_r)
        # tr = Geom::Transformation.axes(pt1, *axes)
        # pt1, pt2, pt3 = [pt1, pt2, pt3].map { |pt| pt.transform(tr_r).transform(vec_01_r) }
        # # pt1, pt2, pt3 = [pt1, pt2, pt3].map { |pt| pt.transform(tr) }
        # add_polyline(ents, [pt1, pt2, pt3])

        # x1 = pt1.x; x2 = pt2.x; x3 = pt3.x
        # y1 = pt1.y; y2 = pt2.y; y3 = pt3.y
        # a = x1 - x2
        # b = y1 - y2
        # c = x1 - x3
        # d = y1 - y3
        # e = ((x1 * x1 - x2 * x2) + (y1 * y1 - y2 * y2)) / 2.0
        # f = ((x1 * x1 - x3 * x3) + (y1 * y1 - y3 * y3)) / 2.0
        # det = b * c - a * d
        # return -1 if det.abs < 0.0001
        # x0 = -(d * e - b * f) / det
        # y0 = -(a * f - c * e) / det
        # radius = math.hypot(x1 - x0, y1 - y0)

      end

      # Counter-clockwise angle from vector2 to vector1, as seen from normal.
      def self.angle_in_plane(vector1, vector2, normal = Z_AXIS)
        Math.atan2((vector2 * vector1) % normal, vector1 % vector2)
      end

      def self.edge_angle(edge)
        angle = angle_in_plane(edge.faces[0].normal, edge.faces[1].normal, edge.line[1])

        # Assuming mesh is oriented, i.e. edge is reversed in exactly one out of the two
        # faces. If not, the return value depends the order the faces are presented in.
        edge.reversed_in?(edge.faces[0]) ? angle : -angle
      end

      def self.gen_group
        Sketchup.active_model.active_entities.add_group
      end

      def self.add_polyline(ents, pts)
        pts.each_index do |i|
          next if i == 0
          pt_this = pts[i]
          pt_last = pts[i - 1]
          ents.add_line(pt_last, pt_this)
        end
      end

      def self.gen_group_by_grp(grp)
        grp.entities.add_group
      end

      def self.gen_grp_or_by_grp(grp_parent)
        grp_parent ? gen_group_by_grp(grp_parent) : gen_group
      end

      def self.m_line(lst_xyz1, lst_xyz2)
        pt1 = m_point(lst_xyz1[0], lst_xyz1[1], lst_xyz1[2])
        pt2 = m_point(lst_xyz2[0], lst_xyz2[1], lst_xyz2[2])
        [pt1, pt2]
      end

      def self.m_color(r, g, b, alpha = 200)
        Sketchup::Color.new(r, g, b, alpha)
      end

      def self.m_sphere(ents, cpt, radius)
        circle = ents.add_circle(cpt, Y_AXIS, radius)
        circle_face = ents.add_face circle
        path = ents.add_circle(cpt, Z_AXIS, radius + 1)
        circle_face.followme path
        ents.erase_entities path
        ents
      end


      def self.m_cpt(pt1, pt2)
        Geom.linear_combination(0.5, pt1, 0.5, pt2)
      end

      def self.positive_face?(f)
        f.normal == Z_AXIS
      end

      def self.negtive_face?(f)
        f.normal == Z_AXIS.reverse
      end

      def self.reverse_faces(ent)
        faces = ent.grep(Sketchup::Face)
        faces.each { |f| f.reverse! }
        faces
      end

      def self.reserve_negtive_face(face)
        face.reverse! if negtive_face?(face)
      end

      def self.normal_of_pts(pts)
        len_pts = pts.size
        v1 = pts[1] - pts[0]
        i2 = 2; i1 = 1
        v2 = pts[i2] - pts[i1]
        while v2.dot(v1) == 0.0
          i2 += 1; i1 += 1
          return false if i2 == len_pts
          v2 = pts[i2] - pts[i1]
        end
        normal = v1.cross(v2).normalize
      end

      def self.num2list(num)
        list = []
        if num <= 1
          list = [0]
        else
          (0...num).each { |i| list << i }
        end
        list
      end

      def self.linspace(init_val, last, num)
        arr = (0..num)
        step = (last - init_val).to_f / num
        arr = arr.map { |i| init_val + i * step }
        return arr
      end

      # Modify【2021-06-30 23:58:40】【增加return [first] if diff == 0】
      def self.frange(first, last, diff = 1)
        return [first] if diff == 0
        Range.new(first, last).step(diff).to_a
      end

      def self.frange_pop(first, last, diff = 1)
        return [first] if diff == 0
        range = frange(first, last, diff)
        range.pop
        range
      end

      def self.floodfill(image, x, y, origColor, newColor)
        return unless self.inArea(image, x, y) # 出界：超出数组边界
        return if (image[x][y] != origColor)
        return if (image[x][y] == -1)
        image[x][y] = -1;
        self.floodfill(image, x, y + 1, origColor, newColor);
        self.floodfill(image, x, y - 1, origColor, newColor);
        self.floodfill(image, x - 1, y, origColor, newColor);
        self.floodfill(image, x + 1, y, origColor, newColor);
        image[x][y] = newColor;
      end

      def self.inArea(image, x, y)
        x >= 0 && x < image.length && y >= 0 && y < image[0].length
      end

      def self.set_material(name, color, alpha = 1)
        model = Sketchup.active_model
        materials = model.materials
        mat_ab = materials.add(name)
        mat_ab.color = color
        mat_ab.alpha = alpha
        mat_ab
      end

      def self.face_hitted_is_tree_up?(obj_hitted)
        return false unless obj_hitted.is_a?(Sketchup::Face)
        return false unless Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_TYPE) == TYP_C::CV_TREE
        return true if obj_hitted.normal.z < 0
        false
      end

      def self.face_hitted_is_tree_bottom?(obj_hitted)
        return false unless obj_hitted.is_a?(Sketchup::Face)
        return false unless Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_TYPE) == TYP_C::CV_TREE
        return true if obj_hitted.normal.z > 0
        false
      end

      def self.face_hitted_is_stuff_transmit?(obj_hitted)
        return false unless obj_hitted.is_a?(Sketchup::Face)
        return true if Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_TYPE) == TYP_C::CV_TREE
        return true if Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_TYPE) == TYP_C::CV_SUNSHADE_BOARD
        false
      end

      def self.face_hitted_is_grey_space?(obj_hitted)
        return false unless obj_hitted.is_a?(Sketchup::Face)
        return false unless [STR_C::CV_CO_STRC, STR_C::CV_BR_STRC].include? Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_TYPE)
        return true if Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_STRC) == STR_C::CVA_ROOFSOFFIT_INNER
        false
      end

      def self.face_hitted_is_ground?(obj_hitted)
        return false unless obj_hitted.is_a?(Sketchup::Face)
        return true if Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_TYPE) == TYP_C::CV_GROUND
        false
      end

      def self.face_hitted_is_measurePt?(obj_hitted)
        return false unless obj_hitted.is_a?(Sketchup::Face)
        obj_hitted.get_attribute(ATTR_DICT_PROTOTOOL_ABSTRACTION, attr, nil)
        return true unless Sp.fetch_attr_from_house3d_ent(obj_hitted, KEY_C::CK_NAME).nil?
        false
      end

      def self.set_material2face(face, mat_ab)
        return unless face.is_a?(Sketchup::Face)
        face.material = mat_ab
        face.back_material = mat_ab
        face
      end

      def self.set_face_material(face, m_name = 'default', m_color = 'red', m_alpha = 1)
        return unless face.is_a?(Sketchup::Face)
        mat_ab = set_material(m_name, m_color, m_alpha)
        face.material = mat_ab
        face.back_material = mat_ab
        face
      end

      def self.fetch_first_pt_z_of_faces(faces_ground_top, tr)
        faces_ground_top.first.vertices.first.position.transform(tr).z
      end

      def self.find_parent_grp_of_face(face)
        face.parent.instances[-1] if face && face.parent.is_a?(Sketchup::ComponentDefinition) && face.parent.group?
      end

      def self.z_lowest_of_cp(cp_grp)
        cp_grp.bounds.min.z
      end

      def self.pt4_of_bounds_of_cp(cp_grp)
        bb = cp_grp.bounds
        bb_min = bb.min
        bb_max = bb.max
        bb_min.z = 0
        bb_max.z = 0
        path_viewport = []
        path_viewport << bb_min
        path_viewport << Geom::Point3d.new(bb_max.x, bb_min.y, 0)
        path_viewport << bb_max
        path_viewport << Geom::Point3d.new(bb_min.x, bb_max.y, 0)
        return bb_min, path_viewport
      end

      def self.set_face_material_defined(face, mat_ab)
        return unless face.is_a?(Sketchup::Face)
        face.material = mat_ab
        face.back_material = mat_ab
        face
      end

      def self.set_material2grp(grp, mat_ab)
        grp.entities.to_a.each do |face|
          if face.is_a?(Sketchup::Face)
            face.material = mat_ab
            face.back_material = mat_ab
          end
        end
      end

      def self.set_color2grp(grp, m_name, m_color, m_alpha = 1)
        mat_ab = set_material(m_name, m_color, m_alpha)
        grp.entities.to_a.each do |face|
          if face.is_a?(Sketchup::Face)
            face.material = mat_ab
            face.back_material = mat_ab
          end
        end
      end

      def self.operate_grp_of_sels
        model = Sketchup.active_model
        selection = model.selection
        grps = selection.grep(Sketchup::Group)
        yield grps
        selection.clear
        selection.add grps
      end

      def self.switch_layer(new_layer, old_layer = nil)

        model = Sketchup.active_model
        if old_layer.nil?
          old_layer = model.active_layer
        end
        layers = model.layers
        layers.add(new_layer)

        model.active_layer = new_layer

        yield

        self.show_layers
        model.active_layer = old_layer
      end

      def self.show_layers
        show_layer = lambda { |l| l.visible = true }
        model = Sketchup.active_model
        model.layers.each { |l| show_layer.call(l) }
      end

      def self.lines_x_lines(lines1, lines2)
        lines1.each_with_index { |line1, i_lines1|
          lines2.each_with_index { |line2, i_lines2|
            next unless (pt_x = Geom.intersect_line_line(line1, line2))
            next unless Prototool.pt_on_seg?(pt_x, line1, false, 0.1)
            next unless Prototool.pt_on_seg?(pt_x, line2, false, 0.1)
            yield(line1, i_lines1, line2, i_lines2, pt_x)
          }
        }
      end


      def self.pts2polyline(pts, end2end = true)
        lines = []
        pts.each_index do |i|
          unless end2end
            next if i == 0
          end
          lines << [pts[i - 1], pts[i]]
        end
        lines
      end

      def self.pt_inner_path?(pt, path, check_border = true)
        Geom.point_in_polygon_2D(pt, path, check_border)
      end

      def self.uppack_face_bb(face, z_level, linspace = 10)
        bb = face.bounds
        bb_min = bb.min; bb_min.z = z_level
        bb_max = bb.max; bb_max.z = z_level
        min_length_domain = [bb_max.x - bb_min.x, bb_max.y - bb_min.y].min
        step_domain = (min_length_domain / linspace).round
        x_range = bb_max.x - bb_min.x
        x_num = x_range / step_domain
        y_range = bb_max.y - bb_min.y
        y_num = y_range / step_domain
        pt_start = m_point(bb_min.x - step_domain * 1.5, bb_min.y - step_domain * 1.5, z_level)
        pts_matrix = init_array2d(x_num + 3, y_num + 3)
        return pt_start, pts_matrix, step_domain, x_num, y_num
      end


      def self.pt_in_face?(pt, face, check_edge = true, check_vertices = true)
        ref = [Sketchup::Face::PointInside, Sketchup::Face::PointOnFace]
        ref << Sketchup::Face::PointOnEdge if check_edge
        ref << Sketchup::Face::PointOnVertex if check_vertices
        result = face.classify_point(pt)
        if ref.include?(result)
          true
        else
          false
        end
      end

      def self.fetch_time_now
        time = Time.now
        info = {:year => time.year,
                :month => time.month,
                :day => time.day,
                :hour => time.hour + 1,
                :minute => 0, #time.min,
                :second => 0, #time.sec
        }
      end

      def self.timezone_i2str(time_zone)
        sign = (time_zone < 0) ? '-' : '+'
        str_num = "%02d" % time_zone.abs
        str_num += '00'
        str_num = sign + str_num
      end


      def self.info_time2time_1(info_shadow_time)
        y = info_shadow_time[:year]
        m = info_shadow_time[:month]
        d = info_shadow_time[:day]
        hour = info_shadow_time[:hour]
        minute = info_shadow_time[:minute]
        second = info_shadow_time[:second]
        time = Time.utc(y, m, d, hour, minute, second)
      end

      def self.info_time2time(info_shadow_time, time_zone)
        y = info_shadow_time[:year]
        m = info_shadow_time[:month]
        d = info_shadow_time[:day]
        hour = hour_add(info_shadow_time[:hour], time_zone)
        minute = info_shadow_time[:minute]
        second = info_shadow_time[:second]
        time = Time.local(y, m, d, hour, minute, second)
      end

      def self.time2token(info_shadow_time, time_zone)
        y = "%04d" % info_shadow_time[:year]
        m = "%02d" % info_shadow_time[:month]
        d = "%02d" % info_shadow_time[:day]
        hour = "%02d" % hour_add(info_shadow_time[:hour], time_zone)
        minute = "%02d" % info_shadow_time[:minute]
        second = "%02d" % info_shadow_time[:second]
        time_zone = timezone_i2str(time_zone)
        token = y + '-' + m + '-' + d + ' ' + hour + ':' + minute + ':' + second + ' ' + time_zone
      end

      def self.hour_add(h, to_add)
        h_new = h + to_add
        h_new -= 24 if h_new >= 24
        h_new
      end

      def self.fetch_shadow_info
        model = Sketchup.active_model
        shadow_info = model.shadow_info
      end


      def self.fetch_shadow_time
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        # shadow_info['City'] = @city
        # shadow_info['Longitude'] = @lon
        # shadow_info['Latitude'] = @lat
        time = shadow_info['ShadowTime']
        tz = shadow_info['TZOffset']
        y, m, d, hour, minute, second = parse_shadow_time(time)
        info = {:year => y,
                :month => m,
                :day => d,
                :hour => hour,
                :minute => minute,
                :second => second
        }
      end

      def self.parse_shadow_time(time)
        time = time.to_s
        str_daily, str_secondly, str_timezone = time.split(' ').to_a
        y, m, d = str_daily.split('-').map(&:to_i)
        hour, minute, second = str_secondly.split(':').map(&:to_i)
        [y, m, d, hour, minute, second]
      end

      def self.jsonString2hash(jsonString)
        res = /(?<={).*(?=})/.match(jsonString)
        Hash[(
             res[0].split(',').map do |token|
               tL = token.split(':')
               tL[1] = yield(tL[1]) if block_given?
               [tL[0][1...-1].to_sym, tL[1]]
             end
             )]
      end


    end

    DRAW_TEXT_GLOBAL_OPTION ||= {
        :font => "Arial",
        :size => 15,
        :color => 'red',
        :bold => true,
        :align => TextAlignLeft
    }
    STR_TO_BE_FOUND ||= 'key:location/Depth temp @ (m)/units/frequency/startsAt/endsAt'
    NUM_OF_EACH_MONTH ||= [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    LIST_MONTH ||= ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']
    PI ||= 180.degrees

    class Psychrometric


      def self.PsyPsatFnTemp_raw(t)
        tkel = t + KelvinConv
        if tkel < 173.15
          pascal = 0.0017
        elsif tkel < KelvinConv
          c1 = -5674.5359
          c2 = 6.3925247
          c3 = -0.9677843e-2
          c4 = 0.62215701e-6
          c5 = 0.20747825e-8
          c6 = -0.9484024e-12
          c7 = 4.1635019
          pascal = Math.exp(c1 / tkel + c2 + tkel * (c3 + tkel * (c4 + tkel * (c5 + c6 * tkel))) + c7 * Math.log(tkel))
        elsif tkel < 473.15
          c8 = -5800.2206
          c9 = 1.3914993
          c10 = -0.048640239
          c11 = 0.41764768e-4
          c12 = -0.14452093e-7
          c13 = 6.5459673
          pascal = Math.exp(c8 / tkel + c9 + tkel * (c10 + tkel * (c11 + tkel * c12)) + c13 * Math.log(tkel))
        else
          pascal = 1555000.0
        end
        return pascal
      end

      def self.PsyPsatFnTemp(t)
        tdb_tag_r = t
        psat = PsyPsatFnTemp_raw(tdb_tag_r)
      end

      def self.PsyWFnTdbTwbPb(tdb, twbin, pb)
        twb = twbin
        twb = tdb if twb > tdb
        pwet = PsyPsatFnTemp(twb)
        wet = 0.62198 * pwet / (pb - pwet)
        w = ((2501.0 - 2.381 * twb) * wet - (tdb - twb)) / (2501.0 + 1.805 * tdb - 4.186 * twb)
        if w < 0.0
          return PsyWFnTdbRhPb(tdb, 0.0001, pb)
        else
          return w
        end
      end

      def self.TskyFnTdbEsky(tdb, twb)
        tdewK = [tdb, twb].min + KelvinConv
        esky = (0.787 + 0.764 * Math.log((tdewK) / KelvinConv))
        return (tdb + KelvinConv) * Math.sqrt(Math.sqrt(esky)) - KelvinConv
      end

    end


    def self.getJD(month, day)
      numOfDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
      return numOfDays[month.to_i - 1] + day.to_i
    end

    def self.begin_time
      @count = 0
      @time = Time.now
    end

    def self.call_time_opt(token, dum = false)
      if dum
        yield
      else
        @count ||= 0
        @count += 1
        time1 = Time.now - @time
        yield
        time2 = Time.now - @time
        token_count_process = '完成步骤' + "%02d" % @count + '：'
        token_time_process_this = (time2 - time1).round(4).inspect + 's'
        token_time_process_all = time2.round(4).inspect + 's'
        p token_count_process + '“' + token + '”共耗时“' + token_time_process_this +
              '”；此时程序共运行了“' + token_time_process_all + '”'
      end
    end

    def self.call_time(token)
      @count ||= 0
      @count += 1
      time1 = Time.now - @time
      yield
      time2 = Time.now - @time
      token_count_process = '完成步骤' + "%02d" % @count + '：'
      token_time_process_this = (time2 - time1).round(4).inspect + 's'
      token_time_process_all = time2.round(4).inspect + 's'
      Sp.p_and_s token_count_process + '“' + token + '”共耗时“' + token_time_process_this +
            '”；此时程序共运行了“' + token_time_process_all + '”'
    end


    def self.separate_list(list, key)
      index_list = []; list_info = []
      list.each_index { |i| (index_list << i; list_info << list[i, 7]) if list[i] == key }
      if index_list.size == 0
        index_list = [-7, list.size]
        list_info = [[key, 'somewhere', 'someData', 'someUnits', 'someTimeStep', [1, 1, 1], [12, 31, 24]]]
      else
        index_list << list.size
      end
      return index_list, list_info
    end


    # Purpose: 【:lowB, :highB, :numSeg, :customColors, :legendBasePoint, :legendScale,
    #            :legendFont, :legendFontSize, :legendBold, :decimalPlaces, :removeLessThan】
    def self.read_paras_legend(paras_legend)
      if paras_legend == []
        list_info_keys = [:lowB, :highB, :numSeg, :customColors, :legendBasePoint, :legendScale,
                          :legendFont, :legendFontSize, :legendBold, :decimalPlaces, :removeLessThan]
        info = Hash[list_info_keys.map { |item| [item, nil] }]
      else
        info = paras_legend
      end
      info[:lowB] = set_item_float(info[:lowB], 'min')
      info[:highB] = set_item_float(info[:highB], 'max')
      info[:numSeg] = set_item_float(info[:numSeg], 11)
      if info[:customColors].nil? || info[:customColors][0].nil?
        info[:customColors] = [color(75, 107, 169), color(115, 147, 202),
                               color(170, 200, 247), color(193, 213, 208),
                               color(245, 239, 103), color(252, 230, 74),
                               color(239, 156, 21), color(234, 123, 0),
                               color(234, 74, 0), color(234, 38, 0)]
      end
      info[:legendBasePoint] ||= nil
      info[:legendScale] = set_item_float(info[:legendScale], 1)
      info[:legendFont] ||= 'Verdana'
      info[:legendFontSize] ||= nil
      info[:legendBold] ||= false
      info[:decimalPlaces] ||= 2
      info[:removeLessThan] ||= false
      return info
    end

    def self.angle2north(north)
      vec_north = Y_AXIS.clone
      rotation = Geom::Transformation.rotation(ORIGIN, Z_AXIS, north.degrees)
      vec_north = vec_north.transform(rotation)
      [north.degrees, vec_north]
    end

    def self.get_cpt(cpt)
      cpt.nil? ? ORIGIN : cpt
    end


    def self.get_hows_based_on_period(period_analysis, step_time)
      st_month, st_day, st_hour, ed_month, ed_day, ed_hour = read_run_period(period_analysis)
      if st_month > ed_month
        months = frange(st_month, 12) + frange(1, ed_month)
      else
        months = frange(st_month, ed_month)
      end

      hours = frange(st_hour, ed_hour - 1)
      days = [st_day, ed_day]
      hoys = get_hoys(hours, days, months, step_time, 1)
      [hoys, months, days]
    end

    def self.check_latitude(latitude)
      if latitude.to_f >= 90
        latitude = 89.9
      elsif latitude.to_f <= -90
        latitude = -89.9
      end
      latitude
    end

    private

    def self.readRunPeriod(runningPeriod, p = true, full = true)
      if !runningPeriod || runningPeriod[0].nil?
        runningPeriod = [[1, 1, 1], [12, 31, 24]]
      end

      stMonth = runningPeriod[0][0]; stDay = runningPeriod[0][1]; stHour = runningPeriod[0][2]
      endMonth = runningPeriod[1][0]; endDay = runningPeriod[1][1]; endHour = runningPeriod[1][2]

      if p
        startDay = hour2date(date2hour(stMonth, stDay, stHour))
        startHour = startDay.split(' ')[-1]
        startDate = startDay.gsub(startHour, "")[0...-1]

        endingDay = hour2date(date2hour(endMonth, endDay, endHour))
        endingHour = endingDay.split(' ')[-1]
        endingDate = endingDay.gsub(endingHour, "")[0...-1]
      end

      #if full:
      #    print 'Analysis period is from', startDate, 'to', endingDate
      #    print 'Between hours ' + startHour + ' to ' + endingHour
      #
      #else: print startDay, ' - ', endingDay

      [stMonth, stDay, stHour, endMonth, endDay, endHour]
    end

    def self.getHOYsBasedOnPeriod(analysisPeriod, timeStep)

      stMonth, stDay, stHour, endMonth, endDay, endHour = readRunPeriod(analysisPeriod, true, false)

      if stMonth > endMonth
        months = Sp.frange(stMonth, 12) + Sp.frange(1, endMonth)
      else
        months = Sp.frange(stMonth, endMonth)
      end
      # end hour shouldn't be included
      hours = Sp.frange(stHour, endHour)
      days = stDay, endDay
      hoys = get_hoys(hours, days, months, timeStep, method = 1)

      [hoys, months, days]

    end

    def self.day_h2hoy(day, hour)
      (day - 1) * 24 + hour
    end

    def self.get_hoys(hours, days, months, step_time, method = 0)
      st_day, ed_day = days if method == 1
      num_of_each_month = NUM_OF_EACH_MONTH
      num_of_hours = step_time * hours.size
      if step_time != 1
        step = 1 / step_time
        hours = frange(hours[0], hours[-1], step)
        hours = hours[0...num_of_hours] if hours.size > num_of_hours
      end
      hoys = []
      months.each_with_index do |m, i_m|
        if method == 1
          if m.size == 1 && st_day - ed_day == 0
            days = [st_day]
          elsif months.size == 1
            days = frange(st_day, ed_day)
          else
            if i_m == 0
              days = frange(st_day, num_of_each_month[m - 1])
            elsif i_m == months.size - 1
              days = frange(1, check_day(ed_day, m))
            else
              days = frange(1, num_of_each_month[m - 1])
            end
          end
        end

        days.each { |d|
          hours.each { |h|
            h = check_hour(h.to_f)
            m = check_month(m.to_i)
            d = check_day(d.to_i, m)
            hoy = date2hour(m, d, h)
            hoys << hoy unless hoys.include?(hoy)
          }
        }
      end
      hoys
    end

    def self.doy2date(doy)
      num_of_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
      hour = doy * 24
      num_of_hours = num_of_days.map { |n_o_d| n_o_d * 24 }
      if hour % 8760 == 0
        return 31, 11
      end

      s_month = nil
      last_h = nil
      num_of_hours[0...-1].each_index do |h|
        if hour <= num_of_hours[h + 1]
          s_month = LIST_MONTH[h]; last_h = h; break
        end
      end
      last_h ||= num_of_hours.size - 2
      s_month ||= LIST_MONTH[last_h]

      if hour % 24 == 0
        day = ((hour - num_of_hours[last_h]) / 24).to_i
      else
        day = ((hour - num_of_hours[last_h]) / 24).to_i + 1
      end

      month = LIST_MONTH.index(s_month) + 1
      return month, day

    end

    def self.hour2date(hour, alternate = false)
      num_of_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
      num_of_hours = num_of_days.map { |n_o_d| n_o_d * 24 }
      if hour % 8760 == 0
        if alternate
          return 31, 11, 24
        else
          return '31' + ' ' + 'DEC' + '24:00'
        end
      end

      s_month = nil
      last_h = nil
      num_of_hours[0...-1].each_index do |h|
        if hour <= num_of_hours[h + 1]
          s_month = LIST_MONTH[h]; last_h = h; break
        end
      end
      last_h ||= num_of_hours.size - 2
      s_month ||= LIST_MONTH[last_h]

      if hour % 24 == 0
        i_day = ((hour - num_of_hours[last_h]) / 24).to_i
        s_time = '24:00'
        hour = 24
      else
        i_day = ((hour - num_of_hours[last_h]) / 24).to_i + 1
        s_minutes = ((hour - hour.floor) * 60).round.to_i.to_s
        s_minutes = '0' + s_minutes if s_minutes.size == 1
        s_time = (hour % 24).to_i.to_s + ':' + s_minutes
      end

      if alternate
        i_hour = hour % 24
        i_hour = 24 if i_hour == 0
        i_month = LIST_MONTH.index(s_month)
        return i_day, i_month, i_hour
      end

      i_day.to_s + ' ' + s_month + ' ' + s_time

    end

    def self.date2hour(month, day, hour)
      num_of_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
      jd = num_of_days[month.to_i - 1] + day.to_i
      (jd - 1) * 24 + hour
    end


    def self.check_day(day, month)
      if day < 1
        day = 1
      end
      if month == 2 && day > 28
        day = 28
      elsif [4, 6, 9, 11].include?(month) && day > 30
        day = 30
      elsif day > 31
        day == 31
      end
      day
    end

    def self.check_hour(hour)
      if hour < 1
        1
      elsif hour % 24 == 0
        24
      else
        hour % 24
      end
    end

    def self.check_month(month)
      if month < 1
        1
      elsif month % 12 == 0
        12
      else
        month % 12
      end
    end


    def self.read_run_period(period_running)
      unless period_running
        period_running = [[1, 1, 1], [12, 31, 24]]
      end
      st_month = period_running[0][0]; st_day = period_running[0][1]; st_hour = period_running[0][2]
      ed_month = period_running[1][0]; ed_day = period_running[1][1]; ed_hour = period_running[1][2]
      [st_month, st_day, st_hour, ed_month, ed_day, ed_hour]
    end

    def self.color(a, b, c, d = 0)
      Sketchup::Color.new(a, b, c, d)
    end


    def self.frange(first, last, diff = 1)
      Range.new(first, last).step(diff).to_a
    end

    def self.set_item_float(item, default_val)
      if item
        if item == default_val
          item = default_val
        else
          item = item.to_f
        end
      else
        item = default_val
      end
      item
    end

    def self.process(token)
      yield
    end

    def self.operation(token, transparent = false)
      model = Sketchup.active_model
      model.start_operation(token, true, false, transparent)
      ret = yield
      model.commit_operation
      ret
    end

    #{ round_f( number, precision )
    #
    def self.round_f(n, x)
      (n * 10 ** x).round.to_f / 10 ** x
    end

    class Photovoltaics

      # Plane of Array (POA)
      def self.POAirradiance(sunZenithD, sunAzimuthD, srfTiltD, srfAzimuthD, dni, dhi, albedo, beamTransIndex = 1, sef = 1)

        (sunZenithD = 90; sunAzimuthD = 0) if sunZenithD > 90
        dni_shaded = dni * beamTransIndex
        ghi = dhi + dni_shaded * Math.cos(sunZenithD.degrees)

        # convert degree angles to radians:
        srfTiltR = srfTiltD.degrees
        srfAzimuthR = srfAzimuthD.degrees
        sunAzimuthR = sunAzimuthD.degrees
        sunZenithR = sunZenithD.degrees

        # >>>> Purpose【aoi = angle of incidence = 太阳入射角】
        # >>>> Idea【aoi = f(zenith,azimuth,tilt)】
        aoi_r = Math.acos(Math.cos(sunZenithR) * (Math.cos(srfTiltR)) + Math.sin(srfTiltR) * (Math.sin(sunZenithR)) * (Math.cos(srfAzimuthR - sunAzimuthR))) # in radians
        aoi_r = Math::PI if aoi_r > Math::PI
        aoi_r = 0.0 if aoi_r < 0.0
        aoi_d = aoi_r.radians # in degrees

        # Purpose【Incident Irradiance 直接日射辐照度公式】
        # >>>> Purpose【eb = beam irradiance = 直接日射辐照度】
        # >>>> Idea【eb = f(dni_shaded,aoi)】
        ebeam_sky = dni_shaded * Math.cos(aoi_r)
        ebeam_sky = 0.0 if ebeam_sky < 0.0

        # Purpose【Incident Sky Diffuse Irradiance 散射辐射】
        # Purpose【Ed = Diffuse Radiation = 散射辐射】
        # Ed_sky (Perez 1990 modified model diffuse sky irradiance)

        # >>>> Purpose【a，b = the view of the sky from the perspective of the surface = 描述从表面透视的天空视图的参数】
        a = [0, Math.cos(aoi_r)].max
        b = [Math.cos(85.degrees), Math.cos(sunZenithR)].max

        # >>>> Purpose【求解天空清晰度】
        # >>>> Purpose【epsilon = sky clearness = 天空清晰度】
        k = 5.534 * (10 ** (-6)) # for angles in degrees
        divison = 0
        divison = ((dhi + dni_shaded) / dhi) if dhi > 0
        epsilon = (divison + k * (sunZenithD ** 3)) / (1 + k * (sunZenithD ** 3))

        # >>>> Purpose【列出6个经验系数】
        # >>>> Purpose【f11, f12, f13用于求F1，描述太阳周围亮度（circumsolar brightness）】
        # >>>> Purpose【f21, f22, f23用于求F2，描述地平线亮度（horizon brightness）】
        f11, f12, f13, f21, f22, f23 =
            if epsilon <= 1.065
              [-0.0083117, 0.5877285, -0.0620636, -0.0596012, 0.0721249, -0.0220216]
            elsif epsilon > 1.065 and epsilon <= 1.23
              [0.1299457, 0.6825954, -0.1513752, -0.0189325, 0.065965, -0.0288748]
            elsif epsilon > 1.23 and epsilon <= 1.5
              [0.3296958, 0.4868735, -0.2210958, 0.055414, -0.0639588, -0.0260542]
            elsif epsilon > 1.5 and epsilon <= 1.95
              [0.5682053, 0.1874525, -0.295129, 0.1088631, -0.1519229, -0.0139754]
            elsif epsilon > 1.95 and epsilon <= 2.8
              [0.873028, -0.3920403, -0.3616149, 0.2255647, -0.4620442, 0.0012448]
            elsif epsilon > 2.8 and epsilon <= 4.5
              [1.1326077, -1.2367284, -0.4118494, 0.2877813, -0.8230357, 0.0558651]
            elsif epsilon > 4.5 and epsilon <= 6.2
              [1.0601591, -1.5999137, -0.3589221, 0.2642124, -1.127234, 0.1310694]
            else # > 6.2
              [0.677747, -0.3272588, -0.2504286, 0.1561313, -1.3765031, 0.2506212]
            end

        # >>>> Purpose【求解天空亮度】
        # >>>> Purpose【amo = absolute optical air mass = 绝对光学气团】
        amo = 1.0 / (b + 0.15 * (1.0 / ((93.9 - sunZenithD) ** (1.253))))
        # >>>> Purpose【delta = sky brightness = 天空亮度】
        delta = dhi * (amo / 1367.0)

        # >>>> Purpose【求解f1和f2】
        # >>>> Purpose【f11, f12, f13用于求f1，描述太阳周围亮度（circumsolar brightness）】
        # >>>> Purpose【f21, f22, f23用于求f2，描述地平线亮度（horizon brightness）】
        f1 = [0.0, (f11 + delta * f12 + sunZenithR * f13)].max
        f2 = f21 + delta * f22 + sunZenithR * f23

        # isotropic, circumsolar, and horizon brightening components of the sky diffuse irradiance:
        # 散射辐照度由天空中各向同性亮度[di]、环太阳亮度[dc]和地平线亮度[dh]组成:
        if sunZenithD <= 87.5
          d_iso = (dhi * (1.0 - f1) * ((1.0 + Math.cos(srfTiltR)) / 2.0)) * sef
          # 假设太阳周围的所有亮度都集中在太阳的位置（tips：在有阴影的情况下，环太阳亮度[dc]被完全遮挡）
          d_circ = (dhi * f1 * (a / b)) * beamTransIndex
          # 当环境几乎无法看到天空时，才有地平面亮度？
          d_hor = (sef >= 0.05) ? 0.0 : dhi * f2 * Math.sin(srfTiltR)
          # only isotropic brightening component of the sky diffuse irradiance:
          # 当太阳位置很低时，散射辐照度只由天空的各向同性亮度组成:
        else # 87.5 < sunZenithD <= 90
          d_iso = ((1.0 + Math.cos(srfTiltR)) / 2.0) * sef
          d_circ = 0.0
          d_hor = 0.0
        end
        # >>>> Purpose【求解从天空入射的散射辐射】
        edif_sky = d_iso + d_circ + d_hor

        # Purpose【Incident Ground-reflected Irradiance 地面反射的辐照度】
        # >>>> Purpose【Eg = Incident Ground-reflected Irradiance = 地面反射的辐照度】
        # Eg ground reflected irradiance by Liu, Jordan, (1963).
        eref_ground = ((dni_shaded * Math.cos(sunZenithR)) + dhi) * albedo * ((1.0 - Math.cos(srfTiltR)) / 2.0)

        # epoa = Plane of Array Irradiance[阵列平面辐照度] = 直接日射辐照度 + 地面反射的辐照度 + 天空的散射辐射
        epoa = ebeam_sky + eref_ground + edif_sky # in Wh/m2
        epoa = 0.0 if epoa < 0.0

        if ((dni <= 0.0) and (dhi <= 0.0)) or (sunZenithD > 90.0)
          epoa = 0.0; ebeam_sky = 0.0; edif_sky = 0.0; eref_ground = 0.0
        end

        # aoi_r = 太阳入射角
        [epoa, ebeam_sky, edif_sky, eref_ground, sunZenithD, sunAzimuthD]

      end


      #(typ 0.2 for land, 0.25 for vegetation, 0.9 for snow)
      def self.calculateAlbedo(dryBulbTemperature)
        # 修正雪存在的反照率值
        # based on: Metenorm 6 Handbook part II: Theory, Meteotest

        # Purpose: 【计算日平均温度】
        startingDayHOY = 0
        endingDayHOY = 24
        dailyTaAverage = []
        (0...365).each do |_|
          hoysPerDay = dryBulbTemperature[startingDayHOY...endingDayHOY]
          dailyTaAverage << (Sp.sum(hoysPerDay) / 24)
          startingDayHOY += 24
          endingDayHOY += 24
        end
        # Purpose: 【日平均温度往前推14天】
        dailyTaAverageShifted = Sp.roll_arr(dailyTaAverage, -14)

        startingWeekHOY = 0
        endingWeekHOY = 14
        albedoL = []
        lastTwoWeeksTaAverageL = []
        (0...365).each do |i|
          lastTwoWeeksTaAverage = Sp.sum(dailyTaAverageShifted[(startingWeekHOY + i)...(endingWeekHOY + i)]) / 14
          lastTwoWeeksTaAverageL.<<(lastTwoWeeksTaAverage)

          albedo = 0.423 - 0.042 * lastTwoWeeksTaAverage
          albedo = 0.2 if lastTwoWeeksTaAverage > 10
          albedo = 0.8 if lastTwoWeeksTaAverage < -10

          albedo = 0.2 if albedo < 0.2
          albedo = 0.8 if albedo > 0.8

          (0...24).each do |_|
            albedoL << albedo
          end

        end

        return albedoL

      end
    end


  end
end
