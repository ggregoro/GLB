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
config.window_decorations = "TITLE | RESIZE"
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_background_opacity = 0.9

-- Gradient "wallpaper" instead of a flat background. No external image
-- file needed, so it isn't affected by the Flatpak sandbox's read-only
-- $HOME (filesystems=home:ro;xdg-config/wezterm).
config.window_background_gradient = {
	colors = { "#1a1b26", "#0f0f17" },
	orientation = { Linear = { angle = -45.0 } },
	interpolation = "Linear",
	blend = "Rgb",
}

-- ------------------------------------------------------------
-- Behavior
-- ------------------------------------------------------------
config.scrollback_lines = 5000
config.audible_bell = "Disabled"

-- ------------------------------------------------------------
-- Keybindings (tmux-style leader)
-- ------------------------------------------------------------
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

local act = wezterm.action

config.keys = {
	-- press leader twice to send a literal Ctrl+a through
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- tabs
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },

	-- splits
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- pane navigation (vim-style)
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- zoom / resize / copy mode
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
}

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

return config
