
-- Load configuration table.
local defaultConfig = {
	enabled = true,
	cursorStealFix = true,
}
local config = nil

-- Loads the configuration file for use.
local function loadConfig()
	-- Clear any current config values.
	config = {}

	-- First, load the defaults.
	table.copy(defaultConfig, config)

	-- Then load any other values from the config file.
	local configJson = mwse.loadConfig("Runtime Patch")
	if (configJson ~= nil) then
		table.copy(configJson, config)
	end

	mwse.log("[Runtime Patch] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
loadConfig()

-- Do our base hook of the runtime patch.
local runtimePatch = require("RuntimePatch")
runtimePatch.hook()

if (config.cursorStealFix) then
	runtimePatch.hookCursorStealFix()
end
