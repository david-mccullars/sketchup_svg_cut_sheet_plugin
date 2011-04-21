require 'sketchup'
require 'extensions'
require 'svg_cut_sheet/convex_hull'
require 'svg_cut_sheet/cut'
require 'svg_cut_sheet/point_2d'
require 'svg_cut_sheet/pulled_face'

module SvgCutSheet
  class Plugin

    def self.register
      ext = SketchupExtension.new "SvgCutSheet", __FILE__
      ext.description = "This tool creates an SVG file of all wood cuts needed to create the given selection"
      Sketchup.register_extension(ext, true)
      unless defined? $svg_cut_sheet
        $svg_cut_sheet = SvgCutSheet::Plugin.new
        $svg_cut_sheet.add_menu
        $svg_cut_sheet.add_context_menu
      end
    end

    def initialize
      @svg_file = 'v:/cut_sheet.svg'
    end

    def add_context_menu
      UI.add_context_menu_handler do |menu|
        menu.add_separator
        menu.add_item "Create SVG cut sheet" do
          cut_sheet
        end
      end
    end

    def add_menu
      UI::menu("Plugins").add_item "Create SVG cut Sheet" do
        cut_sheet
      end
    end

    def cut_sheet
      return if do_not_overwrite_file?

      cut_hash = {}
      cut_hash.default = 0
      Cut.from_groups(Sketchup.active_model.selection).each do |c|
        cut_hash[c] += 1 unless c.nil?
      end

      Cut.reset_ids
      cut_hash = cut_hash.sort do |a, b|
        v = b[0] <=> a[0]
        v = b[1] <=> a[1] if v == 0
        v
      end

      File.open(@svg_file, 'w') do |io|
        io.write svg {
          yoff = 20.0
          cut_hash.map do |cut, count|
            s = cut.svg(count, yoff)
            yoff += cut.height * 10.0 + 30.0
            s
          end.join("\n")
        }
      end
    end

    def do_not_overwrite_file?
      File.exist?(@svg_file) and 2 == UI.messagebox(
        "#{@svg_file} exists.  Are you sure you want to overwrite?",
        MB_OKCANCEL,
        "Error"
      )
    end

    def svg
      <<-END.gsub(/^\s*/, '')
      <?xml version='1.0' encoding='UTF-8' standalone='no'?>
      <svg xmlns='http://www.w3.org/2000/svg' width='765' height='990'>
      #{yield}
      </svg>
      END
    end
  end
end
