local config = require("UI Expansion.config")
local log = require("UI Expansion.log")

local function onInitialized()
	for id, enabled in pairs(config.components) do
		log:trace("Running component: %s", id)
		local module = include(string.format("UI Expansion.components.%s", id))
		if (enabled and type(module) == "table") then
			module.hook()
		end
	end
end
event.register(tes3.event.initialized, onInitialized)

-- Hook map changes.
local externMapPlugin = include("uiexp_map_extension")
if (externMapPlugin and config.components.mapPlugin) then
	externMapPlugin.hookMapOverrides(config.mapConfig)
end

-- Set up MCM.
dofile("UI Expansion.mcm")
