
local log = require("UI Expansion.log")

--- @class uiexpansion.config
--- @field logLevel string
--- @field components table<string, boolean>
--- @field mapConfig uiexpansion.config.mapConfig
--- @field consoleHistoryLimit number The maximum number of previous entries remembered by the console.
--- @field previousConsoleEntries uiexpansion.config.consoleEntry[]

--- @class uiexpansion.config.mapConfig
--- @field autoMapBounds boolean
--- @field cellResolution number
--- @field minX number
--- @field maxX number
--- @field minY number
--- @field maxY number

--- @class uiexpansion.config.consoleEntry
--- @field lua boolean
--- @field text string

--- @type uiexpansion.config
local defaultConfig = {
	showHelpText = true,
	autoSelectInput = "Magic",
	autoSelectInputAdditional = true,
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
	mapConfig = { autoMapBounds = true, cellResolution = 9, minX = -28, maxX = 28, minY = -28, maxY = 28 },
	components = {
		MenuBarter = true,
		MenuConsole = true,
		MenuContents = true,
		MenuDialog = true,
		MenuInventory = true,
		MenuInventorySelect = true,
		MenuMagic = true,
		MenuMagicSelect = true,
		MenuMap = true,
		MenuMapPlugin = true,
		MenuName = true,
		MenuOptions = true,
		MenuQuantity = true,
		MenuRest = true,
		MenuSaveLoad = true,
		MenuServiceSpells = true,
		MenuServiceTraining = true,
		MenuSpellmaking = true,
		MenuStat = true,
		tooltip = true,
	},
	iconBarLocation = "Bottom",
	iconBarCenterAlign = false,
	logLevel = "INFO",
}

--- @type uiexpansion.config
local config = mwse.loadConfig("UI Expansion", defaultConfig) or defaultConfig--- Convert keybinds from previous to new version.

-- 
-- Convert over previous component IDs.
-- 

local oldComponentsMap = {
	barter = "MenuBarter",
	console = "MenuConsole",
	contents = "MenuContents",
	dialog = "MenuDialog",
	inventory = "MenuInventory",
	inventorySelect = "MenuInventorySelect",
	magic = "MenuMagic",
	magicSelect = "MenuMagicSelect",
	map = "MenuMap",
	mapPlugin = "MenuMapPlugin",
	name = "MenuName",
	options = "MenuOptions",
	quantity = "MenuQuantity",
	rest = "MenuRest",
	saveLoad = "MenuSaveLoad",
	serviceSpells = "MenuServiceSpells",
	spellmaking = "MenuSpellmaking",
	stat = "MenuStat",
	textInput = "textInput",
	tooltip = "tooltip",
	training = "MenuServiceTraining",
}
for old, new in pairs(oldComponentsMap) do
	if config.components[old] ~= nil then
		if (config.components[new] == nil) then
			config.components[new] = config.components[old]
		end
		config.components[old] = nil
	end
end

-- 
-- Convert keybinds
-- 

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

-- Clear deprecated config data.
--- @diagnostic disable
config.version = nil
config.components.textInput = nil
config.mapConfig.autoExpand = nil
--- @diagnostic enable

log:debug("Config loaded: %s", json.encode(config, { indent = true }))

return config