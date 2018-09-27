
local common = require("UI Expansion.common")

-- Configuration table.
local defaultConfig = {
	version = 1.0,
	showHelpText = true,
	autoSelectInput = "Magic",
	useInventoryTextButtons = true,
	selectSpellsOnSearch = true,
	autoFilterToTradable = true,
	mapConfig = {
		autoExpand = true,
		cellResolution = 9,
		minX = -142,
		maxX = 70,
		minY = -59,
		maxY = 29,
	},
	components = {
		barter = true,
		dialog = true,
		inventory = true,
		journal = true,
		magic = true,
		map = false,
		stat = true,
	},
}
local config = table.copy(defaultConfig)

-- Loads the configuration file for use.
local function loadConfig()
	-- Clear any current config values.
	config = {}

	-- First, load the defaults.
	table.copy(defaultConfig, config)

	-- Then load any other values from the config file.
	local configJson = mwse.loadConfig("UI Expansion")
	if (configJson ~= nil) then
		-- Delete any legacy config values.
		config.TEST_dialogueCheck = nil

		-- Merge the configs.
		table.copy(configJson, config)
	end

	common.config = config

	mwse.log("[UI Expansion] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
loadConfig()


-- Reset filtering for all menus when entering menu mode.
local function onEnterMenuMode(e)
	-- Auto-select the desired input box.
	if (config.autoSelectInput == "Inventory") then
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
		local input = menu:findChild(tes3ui.registerID("UIEXP:InventoryMenu:SearchInput"))
		tes3ui.acquireTextInput(input)
	elseif (config.autoSelectInput == "Magic") then
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
		local input = menu:findChild(tes3ui.registerID("UIEXP:MagicMenu:SearchInput"))
		tes3ui.acquireTextInput(input)
	else
		tes3ui.acquireTextInput(nil)
	end

end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })


-- Set up MCM.
local modConfig = require("UI Expansion.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("UI Expansion", modConfig)
end
event.register("modConfigReady", registerModConfig)

-- Run our modules.
local function onInitialized(e)
	if (config.components.barter) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuBarter.lua")
	else
		mwse.log("[UI Expansion] Skipping module: barter")
	end
	if (config.components.dialog) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuDialog.lua")
	else
		mwse.log("[UI Expansion] Skipping module: dialog")
	end
	if (config.components.inventory) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuInventory.lua")
	else
		mwse.log("[UI Expansion] Skipping module: inventory")
	end
	if (config.components.magic) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuMagic.lua")
	else
		mwse.log("[UI Expansion] Skipping module: magic")
	end
	if (config.components.map) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuMap.lua")
	else
		mwse.log("[UI Expansion] Skipping module: map")
	end
	if (config.components.stat) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuStat.lua")
	else
		mwse.log("[UI Expansion] Skipping module: stat")
	end
end
event.register("initialized", onInitialized)

-- Hook map changes.
local extern = include("uiextension")
if (extern and config.components.map) then
	mwse.log("Map Config: %s", json.encode(common.config.mapConfig))
	extern.hookMapOverrides(common.config.mapConfig)
end
