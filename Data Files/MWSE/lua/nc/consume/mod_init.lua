
--[[
	Mod: Controlled Consumption
	Author: NullCascade

	This mod aims to balance the power of alchemy by implementing cooldowns or
	penalties for too much consumption. The mod is meant to be tailored to the
	preference of the user.

	The following configurations are available:
		* Vanilla NPC: A potion can only be consumed once every 5 seconds. This is
		  the same restriction NPCs have in vanilla.
		* Oblivion: Only 4 potions can be active at any one time.
]]--

-- Load the desired configuration module.
local function onInitialized(mod)
	-- Load our choice from the config file.
	local mod = "vanilla_npc"
	local config = json.loadfile("nc_consume_config")
	if (config) then
		mod = config.module
	end

	-- Try to require in the module and register its events.
	currentModule = require("nc.consume.module." .. mod)
	currentModule.onInitialized()
	print("[nc-consume]: Initialized consumption system using " .. mod .. " module.")
end
event.register("initialized", onInitialized)
