
--- @class uiexpansion.config
--- @field logLevel string

--- @type uiexpansion.config
local defaultConfig = {
	version = 1.7,
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
		mapPlugin = true,
		name = true,
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
	iconBarLocation = "Bottom",
	iconBarCenterAlign = false,
	logLevel = "INFO",
}

--- @type musec.config
local config = mwse.loadConfig("UI Expansion", defaultConfig) or defaultConfig--- Convert keybinds from previous to new version.

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

return config