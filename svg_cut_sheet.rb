$LOAD_PATH << File.dirname(__FILE__)

require 'sketchup'
require 'svg_cut_sheet/sketchup_mixins'

SvgCutSheet::SketchupMixins.constants.each do |n|
  Sketchup.const_get(n).class_eval do
    include SvgCutSheet::SketchupMixins.const_get(n)
  end
end

require 'svg_cut_sheet/plugin'
SvgCutSheet::Plugin.register
