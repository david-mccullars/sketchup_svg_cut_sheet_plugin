module SvgCutSheet
  class PulledFace

    def self.all_from_group(group)
      pulled = []
      group.faces.map do |f|
        pf = PulledFace.from_face(f) unless pulled.include? f
        if pf
          pulled << pf.opposite
          pf
        end
      end.compact
    end

    def self.largest_from_group(group)
      all_from_group(group).sort { |a, b| a.depth <=> b.depth }.first
    end

    def self.from_face(face)
      unless face.loops.length == 1
        # puts "#{face.inspect} does not have exactly 1 loop"
        return
      end

      adjacent = face.adjacent_faces

      # Face should have exactly one opposite face
      all = face.all_connected.select { |e| e.typename == 'Face' }
      non_adjacent = all - adjacent - [face]
      unless non_adjacent.size == 1
        # puts "#{face.inspect} has #{non_adjacent.size} non adjacent faces"
        return
      end

      # Opposite face must share same adjacent faces
      opposite = non_adjacent.first
      unless (adjacent & opposite.adjacent_faces).size == adjacent.size
        # puts "#{face.inspect}'s opposite face does not share same adjacent faces"
        return
      end

      # All adjacent faces should be rectangles, perpendicular to face
      n = face.normal
      return PulledFace.new(face, opposite) if adjacent.all? do |f|
        f.is_rectangle? and f.normal.perpendicular? n
      end
    end

    def self.distance_between(face1, face2)
      face1.vertices.first.position.distance_to_plane(face2.plane)
    end

    ###########################################################################

    attr_reader :face, :opposite, :depth

    def initialize(face, opposite)
      @face = face
      @opposite = opposite
      @depth = PulledFace.distance_between(face, opposite)
    end

    def normalized
      shape = face.transform_to_xy_plane

      # If oriented vertically, re-orient horizontally
      if width(shape) < height(shape)
        shape = shape.map { |v| Geom::Point3d.new v.y, v.x, 0 }
      end
      # Make sure we order the vertices in a standard way.
      # The first vertex should have the smallest x value (using smallest y values as a tie-breaker)
      shape = reorder(shape)
      #puts "SHAPE: #{shape}"
      #puts "ALT: #{alt_dis.keys.sort * '|'}"
      cut = Cut.new(shape, min_dis, alt_dis)
      cnt = cut_hash[cut]
      cut_hash[cut] = cnt ? cnt + 1 : 1
    end

  end
end
