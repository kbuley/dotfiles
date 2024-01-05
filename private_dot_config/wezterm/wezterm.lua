local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.font = wezterm.font("FiraCode Nerd Font")
-- config.color_scheme = "GitHub Dark"
-- config.color_scheme = "Molokai"
-- config.color_scheme = "Pro"
config.color_scheme = "Wez"
config.font_size = 12.0

return config
