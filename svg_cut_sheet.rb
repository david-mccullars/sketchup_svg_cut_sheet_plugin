$LOAD_PATH << File.dirname(__FILE__)

require 'sketchup'
require 'svg_cut_sheet/sketchup_mixins'

Sketchup::Group.class_eval do
  include SvgCutSheet::SketchupMixins
end

require 'svg_cut_sheet/plugin'
SvgCutSheet::Plugin.register
