
local common = require("UI Expansion.common")

common.version = 0.6

-- Configuration table.
local defaultConfig = {
	version = common.version,
	showHelpText = true,
	autoSelectInput = "Magic",
	useInventoryTextButtons = true,
	selectSpellsOnSearch = true,
	autoFilterToTradable = true,
	takeFilteredItems = true,
	keybindClose = { 57 },
	keybindTakeAll = { 29, 57 },
	palettes = {
		dialogueTopicSeen = { 0.44, 0.44, 0.44 },
		dialogueTopicUnique = { 0.80, 0.37, 0.17 },
	},
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
		contents = true,
		dialog = true,
		inventory = true,
		inventorySelect = true,
		journal = false,
		magic = true,
		map = false,
		options = true,
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
		if (configJson.version == nil or common.version > configJson.version) then
			configJson.components = nil
		end

		-- Merge the configs.
		table.copy(configJson, config)
	end

	common.config = config

	mwse.log("[UI Expansion] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
loadConfig()


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
	if (config.components.contents) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuContents.lua")
	else
		mwse.log("[UI Expansion] Skipping module: contents")
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
	if (config.components.inventorySelect) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuInventorySelect.lua")
	else
		mwse.log("[UI Expansion] Skipping module: inventorySelect")
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
	if (config.components.options) then
		dofile("Data Files/MWSE/mods/UI Expansion/MenuOptions.lua")
	else
		mwse.log("[UI Expansion] Skipping module: options")
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
