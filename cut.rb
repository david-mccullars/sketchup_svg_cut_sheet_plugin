module SvgCutSheet
  class Cut

    def self.from_groups(groups)
      groups.map do |g|
        if g.typename != 'Group'
          # ignore
        elsif g.contains_group?
          Cut.from_groups(g)
        else
          Cut.new(g)
        end
      end.flatten
    end

    def initialize(group)
      @edges = group.edges
      @faces = group.faces
      @largest_pulled_face = PulledFace.largest_from_group(group)
    end

  end
end
