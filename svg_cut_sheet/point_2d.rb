module SvgCutSheet
  class Point2d

    def initialize(x, y)
      @point = Geom::Point3d.new(x, y, 0)
    end

    def angle_between(p1, p2)
      v1 = @point.vector_to(p1.point_3d)
      v2 = @point.vector_to(p2.point_3d)
      v1.angle_between(v2)
    end

    def distance(p2)
      @point.distance(p2.point_3d)
    end

    def distance_to_line(line_s, line_e)
      line_s = line_s.point_3d
      line_e = line_e.point_3d
      line = [line_s, line_e - line_s]
      @point.distance_to_line(line)
    end

    def x
      @point.x
    end

    def y
      @point.y
    end

    def <=>(p2)
      [@point.x, @point.y] <=> [p2.point_3d.x, p2.point_3d.y]
    end

    def point_3d
      @point
    end

    def to_s
      [@point.x, @point.y].inspect
    end

    def eql?(p2)
      p2.is_a?(Point2d) and x == p2.x and y == p2.y
    end

    def hash
      [x, y].hash
    end

    def ==(p2)
      eql?(p2)
    end

    alias :inspect :to_s

  end
end
