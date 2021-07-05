
local common = require("UI Expansion.common")

common.version = 1.2

-- Configuration table.
local defaultConfig = {
	version = common.version,
	showHelpText = true,
	autoSelectInput = "Magic",
	alwaysClearFiltersOnOpen = true,
	useSearch = true,
	useInventoryTextButtons = true,
	selectSpellsOnSearch = true,
	autoFilterToTradable = true,
	takeFilteredItems = true,
	displayRatio = false,
	transferItemsByDefault = false,
	displayWeekday = true,
	maxWait = 1,
	keybindClose = { tes3.scanCode.space },
	keybindTakeAll = { tes3.scanCode.leftCtrl, tes3.scanCode.space },
	keybindShowAdditionalInfo = { tes3.scanCode.leftAlt },
	keybindMapSwitch = { tes3.scanCode.rightAlt }, -- don't use a standard key to avoid conflicts with filters
	dialogueTopicSeenColor = "journal_finished_quest_color",
	dialogueTopicUniqueColor = "link_color",
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
		console = true,
		contents = true,
		dialog = true,
		inventory = true,
		inventorySelect = true,
		journal = false,
		magic = true,
		map = true,
		mapPlugin = false,
		options = true,
		quantity = true,
		rest = true,
		saveLoad = true,
		serviceSpells = true,
		stat = true,
		tooltip = true,
		training = true,
	},
}
local config = mwse.loadConfig("UI Expansion", defaultConfig)
mwse.log("[UI Expansion] Loaded configuration:")
mwse.log(json.encode(config, { indent = true }))

-- Make config available to the common module.
common.config = config

-- Load translation data.
common.loadTranslation()

-- Make sure we have the latest MWSE version.
if (mwse.buildDate < 20200926) then
	event.register("loaded", function()
		tes3.messageBox(common.dictionary.updateRequired)
	end)
	return
end

-- Set up MCM.
local modConfig = require("UI Expansion.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig(common.dictionary.modName, modConfig)
end
event.register("modConfigReady", registerModConfig)

-- Run our modules.
local function onInitialized()
	if (config.components.barter) then
		dofile("UI Expansion.MenuBarter")
	else
		mwse.log("[UI Expansion] Skipping module: barter")
	end
	if (config.components.console) then
		dofile("UI Expansion.MenuConsole")
	else
		mwse.log("[UI Expansion] Skipping module: console")
	end
	if (config.components.contents) then
		dofile("UI Expansion.MenuContents")
	else
		mwse.log("[UI Expansion] Skipping module: contents")
	end
	if (config.components.dialog) then
		dofile("UI Expansion.MenuDialog")
	else
		mwse.log("[UI Expansion] Skipping module: dialog")
	end
	if (config.components.inventory) then
		dofile("UI Expansion.MenuInventory")
	else
		mwse.log("[UI Expansion] Skipping module: inventory")
	end
	if (config.components.inventorySelect) then
		dofile("UI Expansion.MenuInventorySelect")
	else
		mwse.log("[UI Expansion] Skipping module: inventorySelect")
	end
	if (config.components.magic) then
		dofile("UI Expansion.MenuMagic")
	else
		mwse.log("[UI Expansion] Skipping module: magic")
	end
	if (config.components.map) then
		dofile("UI Expansion.MenuMap")
	else
		mwse.log("[UI Expansion] Skipping module: map")
	end
	if (config.components.mapPlugin) then
		dofile("UI Expansion.MenuMapPlugin")
	else
		mwse.log("[UI Expansion] Skipping module: mapPlugin")
	end
	if (config.components.options) then
		dofile("UI Expansion.MenuOptions")
	else
		mwse.log("[UI Expansion] Skipping module: options")
	end
	if (config.components.quantity) then
		dofile("UI Expansion.MenuQuantity")
	else
		mwse.log("[UI Expansion] Skipping module: quantity")
	end
	if (config.components.rest) then
		dofile("UI Expansion.MenuRest")
	else
		mwse.log("[UI Expansion] Skipping module: rest")
	end
	if (config.components.saveLoad) then
		dofile("UI Expansion.MenuSaveLoad")
	else
		mwse.log("[UI Expansion] Skipping module: save/load")
	end
	if (config.components.serviceSpells) then
		dofile("UI Expansion.MenuServiceSpells")
	else
		mwse.log("[UI Expansion] Skipping module: save/load")
	end
	if (config.components.stat) then
		dofile("UI Expansion.MenuStat")
	else
		mwse.log("[UI Expansion] Skipping module: stat")
	end
	if (config.components.tooltip) then
		dofile("UI Expansion.Tooltip")
	else
		mwse.log("[UI Expansion] Skipping module: tooltip")
	end
	if (config.components.training) then
		dofile("UI Expansion.MenuServiceTraining")
	else
		mwse.log("[UI Expansion] Skipping module: training")
	end
end
event.register("initialized", onInitialized)

-- Hook map changes.
local extern = include("uiextension")
if (extern and config.components.map) then
	mwse.log("Map Config: %s", json.encode(common.config.mapConfig))
	extern.hookMapOverrides(common.config.mapConfig)
end
