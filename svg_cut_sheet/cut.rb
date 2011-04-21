module SvgCutSheet
  class Cut

    def self.reset_ids
      @@id_generator = 'A'
    end

    reset_ids

    def self.from_groups(groups)
      groups.map do |g|
        if g.typename != 'Group'
          # ignore
        elsif g.contains_group?
          from_groups(g.entities)
        else
          from_group(g)
        end
      end.flatten
    end

    def self.from_group(group)
      pulled_face = PulledFace.largest_from_group(group)
      unless pulled_face
        puts "WARNING:  Can not find pulled face on #{group.inspect}"
      else
        verts = pulled_face.face.vertices.map { |v| v.position }
        Cut.new(transform_vertices(verts), pulled_face.depth).orient_to_minimize_height!
      end
    end

    attr_reader :coords, :depth, :height

    def initialize(coords, depth)
      @coords = coords.flatten.map do |p|
        if p.is_a? Point2d
          p
        elsif p.is_a? Geom::Point3d and p.z == 0
          Point2d.new(p.x, p.y)
        else
          raise "Invalid input: #{p}"
        end
      end
      @depth = depth
    end

    def width
      xs = coords.map { |p| p.x }
      xs.max - xs.min
    end

    def centroid
      xsum = coords.inject(0) { |sum, p| sum + p.x }
      ysum = coords.inject(0) { |sum, p| sum + p.y }
      [xsum / coords.size, ysum / coords.size]
    end

    def orient_to_minimize_height!
      # Need to find the convex hull of this shape to avoid concave nastiness
      convex_hull = ConvexHull.calc(@coords)

      # Search for the minimum height
      @height, top, base1, base2 = (1..convex_hull.size).map do |i|
        b1, b2 = convex_hull[i - 1], convex_hull[i % convex_hull.size]
        max = convex_hull.map do |p|
          dis = p.distance_to_line(b1, b2)
          [dis, p]
        end.max
        [max, b1, b2].flatten
      end.min

      b1_i, b2_i = @coords.index(base1), @coords.index(base2)

      # Transform to make base1 new origin and base2 sit on X axis
      shape = @coords.map { |p| p.point_3d }
      shape = Cut.make_vertex_origin(shape, b1_i)
      shape = Cut.rotate_so_vertex_is_on_x_axis(shape, b2_i)
      @coords = shape.map { |p| Point2d.new(p.x, p.y) }

      # Shift along x axis so that all points are positive
      left_most_x = @coords.map { |p| [p.x, p] }.min.last.x
      @coords = @coords.map { |p| Point2d.new(Cut.round_to_prec(p.x - left_most_x), Cut.round_to_prec(p.y).abs) }

      self
    end

    def svgid
      @svgid ||= begin
        id = @@id_generator
        @@id_generator = @@id_generator.next
        if @@id_generator =~ /O$/
          @@id_generator = @@id_generator.next
        end
        id
      end
    end

    def material_desc
      min = [depth, height].min
      max = [depth, height].max
      if min == 0.125
        '1/8" luaun'
      elsif min == 0.25
        '1/4" luaun'
      elsif min == 0.375
        '3/8" plywood'
      elsif min == 0.5
        '1/2" plywood'
      elsif min == 0.625
        '5/8" plywood'
      elsif min == 0.75 and max == 2.5
        '1"x3" board'
      elsif min == 0.75 and max == 3.5
        '1"x4" board'
      elsif min == 0.75 and max == 5.5
        '1"x6" board'
      elsif min == 0.75 and max == 7.5
        '1"x8" board'
      elsif min == 1.5 and max == 1.5
        '2"x2" lumber'
      elsif min == 1.5 and max == 3.5
        '2"x4" lumber'
      elsif min == 1.5 and max == 5.5
        '2"x6" lumber'
      elsif min == 1.5 and max == 7.0
        '2"x8" lumber'
      elsif min == 1.5 and max == 9.0
        '2"x10" lumber'
      elsif min == 1.5 and max == 11.0
        '2"x12" lumber'
      elsif min == 3.5 and max == 3.5
        '4"x4" lumber'
      else
        "Unknown (#{[min, max].inspect})"
      end
    end

    def svg(count, yoff)
      cen_y = centroid[1]
      <<-END
      <g transform="translate(0,#{yoff})">
        <text style="font-size: 20px" x="0" y="#{cen_y * 10.0}">
          <tspan>#{svgid} x #{count}</tspan>
        </text>
        <text style="font-size: 14px" x="0" y="#{cen_y * 10.0 + 15}">
          <tspan>#{material_desc}</tspan>
        </text>
        <path id="path#{svgid}" style="fill:none; stroke:#000000;stroke-width:1px;stroke-opacity:1" d="M #{svg_path} z"/>
        #{svg_path_text}
      </g>
      END
    end

    def svg_path
      coords.map do |p|
        [150.0 + p.x * 10.0, p.y * 10.0] * ','
      end.join(' L ')
    end

    def svg_path_text
      coords.zip((1..coords.size).to_a).map do |v1, i|
        v2 = coords[i % coords.size]
        <<-END
        <text x="#{150.0 + 10.0 * (v1.x + v2.x) / 2 + 1}" y="#{10.0 * (v1.y + v2.y) / 2 - 1}">
          <tspan>#{v1.distance(v2)}</tspan>
        </text>
        END
      end.join("\n")
    end

    def eql?(cut2)
      cut2.is_a?(Cut) and coords == cut2.coords and depth == cut2.depth
    end

    def hash
      coords.hash * 17 + depth.hash
    end

    def ==(cut2)
      eql?(cut2)
    end

    def <=>(cut2)
      v = material_desc <=> cut2.material_desc
      v = width <=> cut2.width if v == 0
      v
    end

    private

    def self.transform_vertices(shape)
      # Pathological case of not enough vertices
      if shape.size < 2
        shape

      elsif parallel_to(:yz_plane, shape)
        shape.map { |v| Geom::Point3d.new(v.y, v.z, 0) }

      elsif parallel_to(:xz_plane, shape)
        shape.map { |v| Geom::Point3d.new(v.x, v.z, 0) }

      elsif parallel_to(:xy_plane, shape)
        shape.map { |v| Geom::Point3d.new(v.x, v.y, 0) }

      # Otherwise, we'll need to transform this:
      else
        shape = make_vertex_origin(shape, 0)
        shape = rotate_so_vertex_is_on_x_axis(shape, 1)

        # Find a point not on xy plane (if exists)
        second_v = shape[1]
        third_v = shape.find { |p| round_to_prec(p.z) != 0 }

        # Now rotate about the x axis so rest of vertices are on the xy plane
        unless third_v.nil?
          theta = round_to_prec(third_v.y) == 0 ? Math::PI / 2 : Math.atan(third_v.z / third_v.y)
          if round_to_prec(theta) != 0
            trans = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), second_v, -theta)
            shape = shape.map { |v| v.transform(trans) }
          end
        end

        shape.map { |v| Geom::Point3d.new(round_to_prec(v.x), round_to_prec(v.y), 0) }
      end
    end

    def self.make_vertex_origin(shape, index)
      base = shape[index]
      shape.map { |p| p - base }
    end

    def self.rotate_so_vertex_is_on_x_axis(shape, index)
      vertex = shape[index]
      unless round_to_prec(vertex.y) == 0 and round_to_prec(vertex.z) == 0
        new_vertex = Geom::Vector3d.new(vertex.length, 0, 0)
        axis = new_vertex.cross(vertex)
        theta = new_vertex.angle_between(vertex)
        if axis.length > 0 and round_to_prec(theta) != 0
          trans = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), axis, -theta)
          shape = shape.map { |v| v.transform(trans) }
        end
      end
      shape
    end

    def self.parallel_to(plane, shape)
      dir = (%w(x y z) - plane.to_s.sub(/_.*/, '').split('')).first
      first = round_to_prec(shape.first.send(dir))
      shape.all? { |v| round_to_prec(v.x) == first }
    end

    def self.round_to_prec(val, prec=256.0)
      val = (val * prec).round / prec
      val == -0 ? 0 : val
    end

  end
end
