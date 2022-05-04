local common = require("UI Expansion.common")

common.version = 1.6

-- Configuration table.
local defaultConfig = {
	version = common.version,
	showHelpText = true,
	autoSelectInput = "Magic",
	alwaysClearFiltersOnOpen = true,
	useSearch = true,
	useSearchEffects = true,
	useSearchSouls = true,
	useSearchTypes = true,
	useInventoryTextButtons = true,
	selectSpellsOnSearch = true,
	autoFilterToTradable = true,
	takeFilteredItems = true,
	displayRatio = false,
	transferItemsByDefault = false,
	displayWeekday = true,
	displayRestTargetHour = true,
	changeMapModeOnCellChange = true,
	displayPlayerDialogueChoices = true,
	maxWait = 1,
	consoleHistoryLimit = 10,
	keybindTakeAll = { keyCode = tes3.scanCode.space, isShiftDown = false, isControlDown = true, isAltDown = false },
	keybindShowAdditionalInfo = {
		keyCode = tes3.scanCode.leftAlt,
		isShiftDown = false,
		isControlDown = false,
		isAltDown = true,
	},
	keybindMapSwitch = { keyCode = tes3.scanCode.rightAlt, isShiftDown = false, isControlDown = false, isAltDown = true }, -- don't use a standard key to avoid conflicts with filters
	dialogueTopicSeenColor = "journal_finished_quest_color",
	dialogueTopicUniqueColor = "link_color",
	mapConfig = { autoExpand = true, cellResolution = 9, minX = -142, maxX = 70, minY = -59, maxY = 29 },
	components = {
		barter = true,
		console = true,
		contents = true,
		dialog = true,
		inventory = true,
		inventorySelect = true,
		journal = false,
		magic = true,
		magicSelect = true,
		map = true,
		mapPlugin = false,
		options = true,
		quantity = true,
		rest = true,
		saveLoad = true,
		serviceSpells = true,
		spellmaking = true,
		stat = true,
		textInput = true,
		tooltip = true,
		training = true,
	},
}
local config = mwse.loadConfig("UI Expansion", defaultConfig) --- @type table<string, any>

--- Convert keybinds from previous to new version.
--- @param keyArray number[]
--- @return table
local function convertKeyBind(keyArray)
	-- Don't convert already converted bindings.
	if (keyArray.keyCode) then
		-- But do make sure no botched config merges make it through.
		return {
			keyCode = keyArray.keyCode,
			isShiftDown = keyArray.isShiftDown,
			isControlDown = keyArray.isControlDown,
			isAltDown = keyArray.isAltDown,
		}
	end

	-- Actually convert.
	local keyBind = {}
	for _, code in ipairs(keyArray) do
		if (code == tes3.scanCode.leftShift or code == tes3.scanCode.rightShift) then
			keyBind.isShiftDown = true
		elseif (code == tes3.scanCode.leftControl or code == tes3.scanCode.rightControl) then
			keyBind.isControlDown = true
		elseif (code == tes3.scanCode.leftAlt or code == tes3.scanCode.rightAlt) then
			keyBind.isAltDown = true
		else
			keyBind.keyCode = code
		end
	end

	-- Ensure that a keybind was actually assigned.
	if (not keyBind.keyCode) then
		keyBind.keyCode = keyArray[1]
	end

	return keyBind
end
config.keybindTakeAll = convertKeyBind(config.keybindTakeAll)
config.keybindShowAdditionalInfo = convertKeyBind(config.keybindShowAdditionalInfo)
config.keybindMapSwitch = convertKeyBind(config.keybindMapSwitch)

-- Make config available to the common module.
common.config = config

-- Make sure we have the latest MWSE version.
if (mwse.buildDate < 20211126) then
	event.register("loaded", function()
		tes3.messageBox(common.i18n("core.updateRequired"))
	end)
	return
end

-- Set up MCM.
dofile("UI Expansion.mcm")

-- Run our modules.
local function onInitialized()
	if (config.components.barter) then
		dofile("UI Expansion.MenuBarter")
	end
	if (config.components.console) then
		dofile("UI Expansion.MenuConsole")
	end
	if (config.components.contents) then
		dofile("UI Expansion.MenuContents")
	end
	if (config.components.dialog) then
		dofile("UI Expansion.MenuDialog")
	end
	if (config.components.inventory) then
		dofile("UI Expansion.MenuInventory")
	end
	if (config.components.inventorySelect) then
		dofile("UI Expansion.MenuInventorySelect")
	end
	if (config.components.magic) then
		dofile("UI Expansion.MenuMagic")
	end
	if (config.components.magicSelect) then
		dofile("UI Expansion.MenuMagicSelect")
	end
	if (config.components.map) then
		dofile("UI Expansion.MenuMap")
	end
	if (config.components.mapPlugin) then
		dofile("UI Expansion.MenuMapPlugin")
	end
	if (config.components.options) then
		dofile("UI Expansion.MenuOptions")
	end
	if (config.components.quantity) then
		dofile("UI Expansion.MenuQuantity")
	end
	if (config.components.rest) then
		dofile("UI Expansion.MenuRest")
	end
	if (config.components.saveLoad) then
		dofile("UI Expansion.MenuSaveLoad")
	end
	if (config.components.serviceSpells) then
		dofile("UI Expansion.MenuServiceSpells")
	end
	if (config.components.spellmaking) then
		dofile("UI Expansion.MenuSpellmaking")
	end
	if (config.components.stat) then
		dofile("UI Expansion.MenuStat")
	end
	if (config.components.tooltip) then
		dofile("UI Expansion.Tooltip")
	end
	if (config.components.training) then
		dofile("UI Expansion.MenuServiceTraining")
	end
	if (config.components.textInput) then
		dofile("UI Expansion.textInput")
	end
end
event.register("initialized", onInitialized)

-- Hook map changes.
local extern = include("uiextension")
if (extern and config.components.map) then
	mwse.log("Map Config: %s", json.encode(common.config.mapConfig))
	extern.hookMapOverrides(common.config.mapConfig)
end
