module SuperCat
  module Sunpath

    unless file_loaded?(__FILE__) # file_loaded?-file_loaded体

      PLUGIN_ID = File.basename(__FILE__, ".rb")
      PLUGIN_ROOT = File.expand_path(File.dirname(__FILE__))
      PLUGIN_DIR = File.join PLUGIN_ROOT, PLUGIN_ID
      PLUGIN_DIR_LIB = File.join PLUGIN_ROOT, 'rzw_Lib2'
      PLUGIN_NAME = "Sunpath"
      REQUIRED_SU_VERSION = "15"
      VERSION     = "0.0.1"
      Strings = LanguageHandler.new(PLUGIN_ID + ".strings")

      ex = SketchupExtension.new(PLUGIN_NAME, File.join(PLUGIN_DIR, "main"))

      ex.description = "Make a sun path"
      ex.version = "1.0.1"
      ex.copyright = "GNU GPL V.3+"
      ex.creator = "Renzhi Wu, renzhiwuscut@gmail.com"

      Sketchup.register_extension(ex, true)

      file_loaded(__FILE__)
    end
  end
end
