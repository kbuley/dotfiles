local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.window_decorations = "TITLE | RESIZE"

config.font = wezterm.font("FiraCode Nerd Font")
-- config.color_scheme = "GitHub Dark"
-- config.color_scheme = "Molokai"
-- config.color_scheme = "Pro"
-- config.color_scheme = "Wez"
-- config.color_scheme = "Hardcore"
config.color_scheme = "catppuccin-mocha"
config.font_size = 12.0

config.window_frame = {
	font = wezterm.font({ family = "FiraCode Nerd Font", weight = "Regular" }),
}

-- Set coloring for inactive panes to be less bright than your active pane
config.inactive_pane_hsb = {
	hue = 0.3,
	saturation = 0.3,
	brightness = 0.3,
}

config.use_fancy_tab_bar = true
config.tab_max_width = 32

config.switch_to_last_active_tab_when_closing_tab = true

config.scrollback_lines = 5000

config.unix_domains = {
	{
		name = "unix",
	},
}

-- Create a status bar on the top right that shows the current workspace and date
wezterm.on("update-right-status", function(window, pane)
	local date = wezterm.strftime(" %I:%M:%S %p  %A  %B %-d ")

	-- Make it italic and underlined
	window:set_right_status(wezterm.format({
		{ Attribute = { Underline = "Single" } },
		{ Attribute = { Italic = true } },
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { AnsiColor = "Silver" } },
		{ Text = date },
	}))
end)

-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

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

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
				}, pane)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- restore ctrl-l functionality
	{ key = "l", mods = "LEADER", action = wezterm.action.ResetTerminal },
	-- move between split panes
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- resize panes
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
	-- mimic copy mode from tmux
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	-- Zoom Zoom
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	-- Tabs
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
	{
		key = ",",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{ key = "t", mods = "LEADER", action = wezterm.action.ShowTabNavigator },
	{ key = "k", mods = "LEADER|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	-- Panes
	{
		-- Vertical split
		key = "|",
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitPane({ direction = "Right", size = { Percent = 50 } }),
	},
	{
		-- Horizontal split
		key = "_",
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitPane({ direction = "Down", size = { Percent = 50 } }),
	},
	-- Rotate Panes
	{ key = "{", mods = "LEADER|SHIFT", action = wezterm.action.RotatePanes("CounterClockwise") },
	{ key = "}", mods = "LEADER|SHIFT", action = wezterm.action.RotatePanes("Clockwise") },
	-- Swap Panes
	{ key = "q", mods = "LEADER", action = wezterm.action.PaneSelect({ mode = "SwapWithActiveKeepFocus" }) },
	-- Muxer
	{
		-- Attach to muxer
		key = "a",
		mods = "LEADER",
		action = wezterm.action.AttachDomain("unix"),
	},
	{
		-- Detach from muxer
		key = "d",
		mods = "LEADER",
		action = wezterm.action.DetachDomain({ DomainName = "unix" }),
	},
	{
		-- Rename workspace
		key = "$",
		mods = "LEADER|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for session",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					wezterm.mux.rename_workspace(window:mux_window():get_workspace(), line)
				end
			end),
		}),
	},
	{
		-- Show list of workspaces
		key = "s",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},
	-- Copy and paste from clipboard
	{ key = "]", mods = "LEADER", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "y", mods = "LEADER", action = wezterm.action.CopyTo("Clipboard") },

	-- Font sizing
	{ key = "+", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },

	-- Send ctrl-B to tmux
	{ key = "b", mods = "LEADER|CTRL", action = wezterm.action.SendKey({ key = "b", mods = "CTRL" }) },
}
-- Move tabs
for i = 1, 8 do
	-- CTRL+ALT + number to move to that position
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CTRL|ALT",
		action = wezterm.action.MoveTab(i - 1),
	})
end

local process_icons = {
	["bash"] = wezterm.nerdfonts.cod_terminal_bash,
	["btm"] = wezterm.nerdfonts.mdi_chart_donut_variant,
	["cargo"] = wezterm.nerdfonts.dev_rust,
	["curl"] = wezterm.nerdfonts.mdi_flattr,
	["docker"] = wezterm.nerdfonts.linux_docker,
	["docker-compose"] = wezterm.nerdfonts.linux_docker,
	["gh"] = wezterm.nerdfonts.dev_github_badge,
	["git"] = wezterm.nerdfonts.fa_git,
	["go"] = wezterm.nerdfonts.seti_go,
	["htop"] = wezterm.nerdfonts.mdi_chart_donut_variant,
	["kubectl"] = wezterm.nerdfonts.linux_docker,
	["kuberlr"] = wezterm.nerdfonts.linux_docker,
	["lazydocker"] = wezterm.nerdfonts.linux_docker,
	["lazygit"] = wezterm.nerdfonts.oct_git_compare,
	["lua"] = wezterm.nerdfonts.seti_lua,
	["make"] = wezterm.nerdfonts.seti_makefile,
	["node"] = wezterm.nerdfonts.mdi_hexagon,
	["nvim"] = wezterm.nerdfonts.custom_vim,
	["psql"] = "󱤢",
	["ruby"] = wezterm.nerdfonts.cod_ruby,
	["stern"] = wezterm.nerdfonts.linux_docker,
	["sudo"] = wezterm.nerdfonts.fa_hashtag,
	["usql"] = "󱤢",
	["vim"] = wezterm.nerdfonts.dev_vim,
	["wget"] = wezterm.nerdfonts.mdi_arrow_down_box,
	["zsh"] = wezterm.nerdfonts.dev_terminal,
}

-- Return the Tab's current working directory
local function get_cwd(tab)
	-- Note, returns URL Object: https://wezfurlong.org/wezterm/config/lua/pane/get_current_working_dir.html
	return tab.active_pane.current_working_dir.file_path or ""
end

-- Remove all path components and return only the last value
local function remove_abs_path(path)
	return path:gsub("(.*[/\\])(.*)", "%2")
end

-- Return the pretty path of the tab's current working directory
local function get_display_cwd(tab)
	local current_dir = get_cwd(tab)
	local HOME_DIR = string.format("file://%s", os.getenv("HOME"))
	return current_dir == HOME_DIR and "~/" or remove_abs_path(current_dir)
end

-- Return the concise name or icon of the running process for display
local function get_process(tab)
	if not tab.active_pane or tab.active_pane.foreground_process_name == "" then
		return "[?]"
	end

	local process_name = remove_abs_path(tab.active_pane.foreground_process_name)
	if process_name:find("kubectl") then
		process_name = "kubectl"
	end

	return process_icons[process_name] or string.format("[%s]", process_name)
end

-- Pretty format the tab title
local function format_title(tab)
	local cwd = get_display_cwd(tab)
	local process = get_process(tab)

	local active_title = tab.active_pane.title
	if active_title:find("- NVIM") then
		active_title = active_title:gsub("^([^ ]+) .*", "%1")
	end

	local description = (not active_title or active_title == cwd) and "~" or active_title
	return string.format(" %s %s/ %s ", process, cwd, description)
end

-- Determine if a tab has unseen output since last visited
local function has_unseen_output(tab)
	if not tab.is_active then
		for _, pane in ipairs(tab.panes) do
			if pane.has_unseen_output then
				return true
			end
		end
	end
	return false
end

-- Returns manually set title (from `tab:set_title()` or `wezterm cli set-tab-title`) or creates a new one
local function get_tab_title(tab)
	local title = tab.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	return format_title(tab)
end

-- Convert arbitrary strings to a unique hex color value
-- Based on: https://stackoverflow.com/a/3426956/3219667
local function string_to_color(str)
	-- Convert the string to a unique integer
	local hash = 0
	for i = 1, #str do
		hash = string.byte(str, i) + ((hash << 5) - hash)
	end

	-- Convert the integer to a unique color
	local c = string.format("%06X", hash & 0x00FFFFFF)
	return "#" .. (string.rep("0", 6 - #c) .. c):upper()
end

local function select_contrasting_fg_color(hex_color)
	-- Based on: https://stackoverflow.com/a/56678483/3219667
	local function calculate_luminance(color)
		-- Extract RGB components from hex color
		local red, green, blue
		red = tonumber(color:sub(1, 2), 16)
		green = tonumber(color:sub(3, 4), 16)
		blue = tonumber(color:sub(5, 6), 16)
		-- Calculate the luminance of the given color and compare against perceived brightness
		return 0.2126 * red / 255 + 0.7152 * green / 255 + 0.0722 * blue / 255
	end

	local color = hex_color:gsub("#", "") -- Remove leading '#'
	local luminance = calculate_luminance(color)
	if luminance > 0.5 then
		return "#000000" -- Black has higher contrast with colors perceived to be "bright"
	end
	return "#FFFFFF" -- White has higher contrast
end

-- Inline tests
local testColor = string_to_color("/Users/kyleking/Developer/ProjectA")
assert(testColor == "#EBD168", "Unexpected color value for test hash (" .. testColor .. ")")
assert(select_contrasting_fg_color("#494CED") == "#FFFFFF", "Expected higher contrast with white")
assert(select_contrasting_fg_color("#128b26") == "#FFFFFF", "Expected higher contrast with white")
assert(select_contrasting_fg_color("#58f5a6") == "#000000", "Expected higher contrast with black")
assert(select_contrasting_fg_color("#EBD168") == "#000000", "Expected higher contrast with black")

-- On format tab title events, override the default handling to return a custom title
-- Docs: https://wezfurlong.org/wezterm/config/lua/window-events/format-tab-title.html
---@diagnostic disable-next-line: unused-local
wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, _max_width)
	local title = get_tab_title(tab)
	local color = string_to_color(get_cwd(tab))

	if tab.is_active then
		return {
			{ Attribute = { Intensity = "Bold" } },
			{ Background = { Color = color } },
			{ Foreground = { Color = select_contrasting_fg_color(color) } },
			{ Text = title },
		}
	end
	if has_unseen_output(tab) then
		return {
			{ Foreground = { Color = "#EBD168" } },
			{ Text = title },
		}
	end
	return title
end)
return config
