module SvgCutSheet
  module SketchupMixins

    module Group
      def entities_by_typename(name)
        entities.select { |e| e.typename == name }
      end

      def groups
        entities_by_typename('Group')
      end

      def faces
        entities_by_typename('Face')
      end

      def edges
        entities_by_typename('Edge')
      end

      def contains_group?
        !groups.empty?
      end
    end

    module Face
      def abs_normal
        n = normal
        (1..3).each do |i|
          return n.reverse if n[i] < 0.0
          return n if n[i] > 0.0
        end
        n
      end

      def is_rectangle?
        # Face must have exactly one loop
        unless loops.size == 1
          # puts "#{inspect} has #{loops.size} loops"
          return false
        end

        # Face must have four vertices
        lp = loops.first
        unless lp.vertices.size == 4
          # puts "#{inspect} has #{lp.vertices.size} vertices"
          return false
        end

        # All angles must be right
        (0..2).all? do |i|
          lp.edges[i].line[1].perpendicular? lp.edges[i + 1].line[1]
        end
      end

      def adjacent_faces
        loops.first.edges.map do |edge|
          edge.faces - [self]
        end.flatten.uniq
      end
    end

  end
end
