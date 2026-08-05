local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ------------------------------------------------------------
-- Font (matches the Nerd Font used across bash/zsh/fish + Starship)
-- ------------------------------------------------------------
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 12.0

-- ------------------------------------------------------------
-- Appearance
-- ------------------------------------------------------------
config.color_scheme = "Tokyo Night"
config.colors = {
	background = "#000000",
}
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- ------------------------------------------------------------
-- Behavior
-- ------------------------------------------------------------
config.scrollback_lines = 5000
config.audible_bell = "Disabled"

return config
