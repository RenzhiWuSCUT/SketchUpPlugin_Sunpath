module SuperCat
  module RZWLIB2

    unless file_loaded?(__FILE__)

      PLUGIN_ID = File.basename(__FILE__, ".rb")
      PLUGIN_ROOT = File.expand_path(File.dirname(__FILE__)) # Public: 加载器文件目录的路径.
      PLUGIN_DIR = File.join PLUGIN_ROOT, PLUGIN_ID # Public: 插件自己目录的路径.
      PLUGIN_NAME = "rzw_Lib2"
      REQUIRED_SU_VERSION = "15"
      VERSION     = "0.0.1"
      StringsLib2 = LanguageHandler.new(PLUGIN_ID + ".strings")

      ex = SketchupExtension.new(PLUGIN_NAME, File.join(PLUGIN_DIR, "main"))

      ex.description = "Prototype tool for CFD plugin for SketchUp." # 插件描述前半段
      ex.version = "1.0.1"
      ex.copyright = "GNU GPL V.3+"
      ex.creator = "Renzhi Wu, renzhiwuscut@gmail.com"

      Sketchup.register_extension(ex, true) # 对已经填好各种信息的SketchupExtension实例进行注册

      file_loaded(__FILE__)
    end
  end
end