local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.font = wezterm.font("FiraCode Nerd Font")
-- config.color_scheme = "GitHub Dark"
-- config.color_scheme = "Molokai"
-- config.color_scheme = "Pro"
-- config.color_scheme = "Wez"
-- config.color_scheme = "Hardcore"
config.color_scheme = "catppuccin-mocha"
config.font_size = 12.0

window_frame = {
	font = wezterm.font({ family = "FiraCode Nerd Font", weight = "Regular" }),
}

config.leader = { key = "p", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Split pane; pane 1 | pane 2
	{
		key = "|",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
	},
	-- Split pane
	-- pane 1
	-- -----
	-- pane 2
	{
		key = "-",
		mods = "LEADER",
		action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }),
	},
	{ key = "z", mods = "ALT", action = wezterm.action.TogglePaneZoomState },
	-- Switch to new or existing workspace
	{
		key = "W",
		mods = "LEADER|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace." },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						wezterm.action.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},
	-- Move between panes
	{ key = "h", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
	{ key = "j", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
	{ key = "k", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
	{ key = "l", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Right" }) },

	-- Mpve between workspaces
	{ key = "n", mods = "LEADER", action = wezterm.action.SwitchWorkspaceRelative(1) },
	{ key = "b", mods = "LEADER", action = wezterm.action.SwitchWorkspaceRelative(-1) },

	-- Copy and paste from clipboard
	{ key = "p", mods = "LEADER", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "y", mods = "LEADER", action = wezterm.action.CopyTo("Clipboard") },

	-- Font sizing
	{ key = "+", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
}

-- Set coloring for inactive panes to be less bright than your active pane
config.inactive_pane_hsb = {
	hue = 0.3,
	saturation = 0.3,
	brightness = 0.3,
}

-- Create a status bar on the top right that shows the current workspace and date
wezterm.on("update-right-status", function(window, pane)
	local date = wezterm.strftime("%Y-%m-%d %H:%M:%S")

	-- Make it italic and underlined
	window:set_right_status(wezterm.format({
		{ Attribute = { Underline = "Single" } },
		{ Attribute = { Italic = true } },
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { AnsiColor = "Silver" } },
		{ Text = window:active_workspace() },
		{ Text = "   " },
		{ Text = date },
	}))
end)

config.hyperlink_rules = {
	-- Matches: a URL in parens: (URL)
	{
		regex = "\\((\\w+://\\S+)\\)",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in brackets: [URL]
	{
		regex = "\\[(\\w+://\\S+)\\]",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in curly braces: {URL}
	{
		regex = "\\{(\\w+://\\S+)\\}",
		format = "$1",
		highlight = 1,
	},
	-- Matches: a URL in angle brackets: <URL>
	{
		regex = "<(\\w+://\\S+)>",
		format = "$1",
		highlight = 1,
	},
	-- Then handle URLs not wrapped in brackets
	{
		regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
		format = "$0",
	},
	-- implicit mailto link
	{
		regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
		format = "mailto:$0",
	},
	{ regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]], format = "mailto:$0" },
	-- file:// URI
	-- Compiled-in default. Used if you don't specify any hyperlink_rules.
	{ regex = [[\bfile://\S*\b]], format = "$0" },
}

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
	regex = [[[^:]["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = "https://www.github.com/$1/$3",
})

-- localhost, with protocol, with optional port and path
table.insert(config.hyperlink_rules, {
	regex = [[http(s)?://localhost(?>:\d+)?]],
	format = "http$1://localhost:$2",
})

-- localhost with no protocol, with optional port and path
table.insert(config.hyperlink_rules, {
	regex = [[[^/]localhost:(\d+)(\/\w+)*]],
	format = "http://localhost:$1",
})

return config
