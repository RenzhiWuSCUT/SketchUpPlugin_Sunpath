module SuperCat

  module Sunpath

    LOCATION_CITIES_PATH ||= File.join(PLUGIN_DIR, "res", "json", "city_database.json")
    OPTION_HTMLDLG = {
        :dialog_title => "Html Dialog",
        :preferences_key => "com.sample.plugin",
        :scrollable => true,
        :resizable => true,
        :width => 600,
        :height => 400,
        :left => 100,
        :top => 100,
        :min_width => 50,
        :min_height => 50,
        :max_width => 1000,
        :max_height => 1000,
        :style => UI::HtmlDialog::STYLE_DIALOG
    }
    HTML_DIALOG_SUNPATH ||= File.join(PLUGIN_DIR, "res", "html", "sun_path_window.html")

  end
end
    