require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'
require File.expand_path('../sketchup_mixins.rb', __FILE__)
require File.expand_path('../cut.rb', __FILE__)
require File.expand_path('../pulled_face.rb', __FILE__)

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
      @svg_file = 'c:/cut_sheet.svg'
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
      p Cut.from_groups(Sketchup.active_model.selection)
    end

    def do_not_overwrite_file?
      File.exist?(@svg_file) and 2 == UI.messagebox(
        "#{@svg_file} exists.  Are you sure you want to overwrite?",
        MB_OKCANCEL,
        "Error"
      )
    end

  end
end

SvgCutSheet::Plugin.register
