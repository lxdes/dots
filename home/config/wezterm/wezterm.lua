local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.initial_cols = 120
config.initial_rows = 28
config.font_size = 12
config.font = wezterm.font("IosevkaTerm Nerd Font")
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.automatically_reload_config = true
config.front_end = "WebGpu"
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.color_scheme = "tokyonight_night"
config.colors = {
	background = "#111117",
}

return config
