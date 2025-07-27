module SuperCat
  module Sunpath

    require "fileutils"
    require "json"
    require 'find'

    current_path = File.dirname(__FILE__)
    if current_path.respond_to?(:force_encoding)
      current_path.force_encoding("UTF-8")
    end

    PLUGIN_ROOT_PATH = current_path.freeze
    PLUGIN_PATH = File.join(PLUGIN_ROOT_PATH, 'sketchup-stl').freeze
    PLUGIN_STRINGS_PATH = File.join(PLUGIN_PATH, 'strings').freeze

    def self.scanf(path)
      list = []
      Find.find(path) do |f|
        list << f
      end
      list.sort
    end

    unless Sketchup.version.to_i >= REQUIRED_SU_VERSION.to_i
      msg = "#{PLUGIN_NAME} requires Sketchup version 20#{REQUIRED_SU_VERSION} or later to run."
      UI.messagebox msg
      raise msg
    end

    plugin_par = File.join PLUGIN_ROOT, PLUGIN_ID
    paths_require_all = scanf(plugin_par)
    paths_require_self = paths_require_all.select { |path| path =~ /\.(rb|rbe)$/ && path =~ /^((?!dbf|0tank).)*$/ }
    paths_require1 = []
    paths_require3 = []
    paths_require1 << File.join(PLUGIN_DIR_LIB, "constantLib")
    paths_require1 << File.join(PLUGIN_DIR, "constant")
    paths_require1 << File.join(PLUGIN_DIR, "preparation")
    paths_require1 << File.join(PLUGIN_DIR, "window", "window")
    paths_require2 = paths_require_self - paths_require1 - paths_require3
    paths_require1.each { |path| Sketchup.require path }
    paths_require2.each { |path| Sketchup.require path }
    paths_require3.each { |path| Sketchup.require path }

    unless file_loaded?(__FILE__) 

      toolbar = UI::Toolbar.new "Sunpath"

      cmd = UI::Command.new("Sunpath Tool") { Sketchup.active_model.select_tool SunpathTool.new() }
      cmd.tooltip = "Make a sun path"
      cmd.status_bar_text = "Make a sun path"
      cmd.small_icon = cmd.large_icon = "res/icon/Sunpath.png"
      toolbar = toolbar.add_item(cmd)

      toolbar.show

      file_loaded(__FILE__)
    end
  end
end
    