local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font_size = 12.0

config.enable_tab_bar = false

config.window_decorations = "RESIZE"

config.color_scheme = 'Tokyo Night'

config.window_background_opacity = 0.92

return config
