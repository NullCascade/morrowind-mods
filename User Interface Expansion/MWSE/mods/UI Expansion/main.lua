local config = require("UI Expansion.config")

local function onInitialized()
	for id, enabled in pairs(config.components) do
		if (enabled) then
			if (lfs.fileexists(string.format("Data Files\\MWSE\\mods\\UI Expansion\\components\\%s.lua", id))) then
				dofile(string.format("UI Expansion.components.%s", id))
			end
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
