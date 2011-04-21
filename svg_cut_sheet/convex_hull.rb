module SvgCutSheet
  class ConvexHull

    def self.calc(points)
      ConvexHull.new(points).send :build
    end

    private

    def initialize(pts)
      @pts = pts.dup
      @hull = []
      @curr_hp = left_most_point
      @prev_hp = point_below(@curr_hp)
    end

    def left_most_point
      @pts.map { |p| [p.x, p] }.min.last
    end

    def point_below(p)
      Point2d.new(p.x, p.y - 1)
    end

    def next_hull_point
      (@pts - [@curr_hp, @prev_hp]).map do |p|
        [@curr_hp.angle_between(p, @prev_hp), p]
      end.max.last
    end

    def build
      while @hull.empty? or @curr_hp != @hull.first
        @hull << @curr_hp
        @prev_hp, @curr_hp = @curr_hp, next_hull_point
      end
      @hull
    end

  end
end
