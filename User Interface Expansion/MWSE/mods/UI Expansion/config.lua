
local log = require("UI Expansion.log")

--- @alias uiexpansion.autoSelectInputOption "Inventory"|"Magic"|"None"

--- @class uiexpansion.config
--- @field alwaysClearFiltersOnOpen boolean When opening the menu, automatically clear all filters. This resets the spells and inventory menus to their default state. Container and barter menus are always reset, even with this option turned off.
--- @field autoFilterToTradable boolean When starting a barter with a merchant, automatically filter the player's inventory to items that that merchant is willing to buy or sell.
--- @field autoSelectInput uiexpansion.autoSelectInputOption When entering menu mode, automatically select the search input for the given menu. This allows for quick searching without having to click on the search box.
--- @field autoSelectInputAdditional boolean This option is independent of `autoSelectInput`. When enabled, opening containers and bartering will have their searchbar selected automatically.
--- @field components table<string, boolean> The enabled state of each module of the mod.
--- @field consoleHistoryLimit number The maximum number of previous entries remembered by the console.
--- @field dialogueTopicSeenColor string|table The color used for topics that have already been seen.
--- @field dialogueTopicUniqueColor string|table The color used for topics that are unique.
--- @field displayPlayerDialogueChoices boolean When enabled, the player's dialogue choices will be printed to the window.
--- @field logLevel mwseLoggerLogLevel How spammy the logs from this mod will be.
--- @field mapConfig uiexpansion.config.mapConfig Subtable of config for the map.
--- @field previousConsoleEntries uiexpansion.config.consoleEntry[]|nil An array of previously used console entries for remembering history.
--- @field showHelpText boolean Help tips appear as white-colored text under most other tooltips. These can help explain new UI Expansion elements that may not be initially obvious.
--- @field takeFilteredItems boolean If true, filtered items will be taken instead of all items in the container.
--- @field transferItemsByDefault boolean By default, items are picked up onto the cursor when selected. With this option enabled, items are instead moved between containers. If in the normal inventory and not a container, items will still be picked up onto the cursor. With this disabled, items can still be quickly transferred by clicking while holding the alt key.
--- @field useInventoryTextButtons boolean When enabled, the vanilla-style filters are given on the inventory menus. When disabled, compact icons will be used instead. This can be useful when playing with narrower menu windows.
--- @field useSearch boolean When enabled, a search bar can be found to the left of other filters. This can be used to filter items or spells by name. The search filter can be cleared by clicking the icon at the right side of the search bar.
--- @field useSearchEffects boolean When enabled, using the search bar will find items and spells whose effects contain the searched for text.\n\nFor example, searching for "fortify luck" will show all items and spells that make use of that effect.
--- @field useSearchSouls boolean When enabled, using the search bar will find soul gems whose contained soul match the searched for text.\n\nFor example, searching for "golden" will show all soul gems that contain a golden saint soul.
--- @field useSearchTypes boolean When enabled, using the search bar will find items whose slot or type contain the searched for text.\n\nFor example, searching for "blunt" will show all blunt weapons. Searching for "amulet" will show all amulets.

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

local renamedComponentsMap = {
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
	training = "MenuServiceTraining",
}
for old, new in pairs(renamedComponentsMap) do
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

--- @param keyArray number[]|mwseKeyCombo
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

--- @diagnostic disable
-- Convet legacy keybinds.
config.keybindTakeAll = convertKeyBind(config.keybindTakeAll)
config.keybindShowAdditionalInfo = convertKeyBind(config.keybindShowAdditionalInfo)
config.keybindMapSwitch = convertKeyBind(config.keybindMapSwitch)

-- Clear deprecated config data.
config.version = nil
config.components.textInput = nil
config.components.journal = nil
config.mapConfig.autoExpand = nil
--- @diagnostic enable

log:setLogLevel(config.logLevel)
log:debug("Config loaded: %s", json.encode(config, { indent = true }))

return config