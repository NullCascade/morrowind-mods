local common = {}

----------------------------------------------------------------------------------------------------
-- Generic helper functions.
----------------------------------------------------------------------------------------------------

-- Performs a test on one or more keys.
function common.complexKeybindTest(keybind)
	local keybindType = type(keybind)
	local inputController = tes3.worldController.inputController
	if (keybindType == "number") then
		return inputController:isKeyDown(keybind)
	elseif (keybindType == "table") then
		for _, k in pairs(keybind) do
			if (not common.complexKeybindTest(k)) then
				return false
			end
		end
		return true
	elseif (keybindType == "string") then
		return inputController:keybindTest(tes3.keybind[keybind])
	end

	return false
end

-- Parses a color from either a table or a string.
function common.getColor(color)
	local colorType = type(color)
	if (colorType == "table" and #color == 3) then
		return color
	elseif (colorType == "string") then
		return tes3ui.getPalette(color)
	end
end

----------------------------------------------------------------------------------------------------
-- Keyboard-to-UI binding helpers.
----------------------------------------------------------------------------------------------------

local currentKeyboardBoundScrollBar = nil
local keyboardScrollBarParams = nil
local keyboardScrollBarNumberInput = nil

local function onKeyDownForScrollBar(e)
	-- Allow enter to fire a submit event.
	if (keyboardScrollBarParams.onSubmit and (e.keyCode == tes3.scanCode.enter or e.keyCode == tes3.scanCode.numpadEnter)) then
		keyboardScrollBarParams.onSubmit()
		return
	end

	local widget = currentKeyboardBoundScrollBar.widget
	local previousValue = widget.current
	local newValue = nil

	if (e.keyCode == tes3.scanCode.keyLeft) then
		-- Allow left to decrease value.
		if (e.isShiftDown) then
			newValue = math.clamp(previousValue - 10, 0, widget.max)
		else
			newValue = math.clamp(previousValue - 1, 0, widget.max)
		end
		keyboardScrollBarNumberInput = 0
	elseif (e.keyCode == tes3.scanCode.keyRight) then
		-- Allow left to increase value.
		if (e.isShiftDown) then
			newValue = math.clamp(previousValue + 10, 0, widget.max)
		else
			newValue = math.clamp(previousValue + 1, 0, widget.max)
		end
		keyboardScrollBarNumberInput = 0
	elseif (e.keyCode == tes3.scanCode["end"]) then
		-- Allow end to go to max value
		newValue = widget.max
		keyboardScrollBarNumberInput = 0
	elseif (e.keyCode == tes3.scanCode.home) then
		-- Allow home to go to 0.
		newValue = 0
		keyboardScrollBarNumberInput = 0
	elseif (e.keyCode == tes3.scanCode.backspace) then
		-- Backspace undoes the most recent input.
		if (keyboardScrollBarNumberInput > 10) then
			newValue = math.floor(keyboardScrollBarNumberInput / 10) - 1
			keyboardScrollBarNumberInput = newValue + 1
		else
			newValue = 0
			keyboardScrollBarNumberInput = 0
		end
	else
		-- Otherwise look for specific number inputs.
		local number = tes3.scanCodeToNumber[e.keyCode]
		if (number) then
			newValue = math.clamp(keyboardScrollBarNumberInput * 10 + number - 1, 0, widget.max)
			keyboardScrollBarNumberInput = newValue + 1
		end
	end

	-- If the value changed, fire off the update event.
	if (newValue ~= nil and newValue ~= previousValue) then
		widget.current = newValue
		if (keyboardScrollBarParams.onUpdate) then
			keyboardScrollBarParams.onUpdate()
		end
		currentKeyboardBoundScrollBar:triggerEvent("PartScrollBar_changed")
	end
end

local function onMouseWheelForScrollBar(e)
	local widget = currentKeyboardBoundScrollBar.widget
	local previousValue = widget.current
	local newValue

	if (e.delta > 0) then
		newValue = math.clamp(previousValue + 1, 0, widget.max)
		keyboardScrollBarNumberInput = 0
	else
		newValue = math.clamp(previousValue - 1, 0, widget.max)
		keyboardScrollBarNumberInput = 0
	end

	if (newValue ~= previousValue) then
		widget.current = newValue
		if (keyboardScrollBarParams.onUpdate) then
			keyboardScrollBarParams.onUpdate()
		end
		currentKeyboardBoundScrollBar:triggerEvent("PartScrollBar_changed")
	end
end

function common.unbindScrollBarFromKeyboard()
	if (currentKeyboardBoundScrollBar == nil) then
		return
	end

	-- Get rid of our key events.
	event.unregister("keyDown", onKeyDownForScrollBar)
	event.unregister("mouseWheel", onMouseWheelForScrollBar)

	-- Clean up any variables we're tracking.
	currentKeyboardBoundScrollBar = nil
	keyboardScrollBarParams = nil
	keyboardScrollBarNumberInput = nil
end

-- Binds a slider to respect keyboard input. Only one slider can be hooked at a time.
function common.bindScrollBarToKeyboard(params)
	-- Get rid of any current binding if applicable.
	common.unbindScrollBarFromKeyboard()

	-- When this element is destroyed, clean up.
	params.element:register("destroy", common.unbindScrollBarFromKeyboard)

	-- Set up the events and variables we'll need later.
	event.register("keyDown", onKeyDownForScrollBar)
	event.register("mouseWheel", onMouseWheelForScrollBar)
	currentKeyboardBoundScrollBar = params.element
	keyboardScrollBarParams = params
	keyboardScrollBarNumberInput = 0
end

----------------------------------------------------------------------------------------------------
-- Expose function to (re)load translations.
----------------------------------------------------------------------------------------------------

function common.loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = require("UI Expansion.translations")
	local dictionary = dictionaries["eng"]

	-- If we aren't doing English, copy over translated entries.
	if (language ~= "eng" and dictionaries[language]) then
		table.copy(dictionaries[language], dictionary)
	end

	-- Set the dictionary.
	common.dictionary = dictionary
end

----------------------------------------------------------------------------------------------------
-- UI Functions
----------------------------------------------------------------------------------------------------

function common.createSearchBar(params)
	local border = params.parent:createThinBorder({})
	border.autoWidth = true
	border.autoHeight = true
	border.widthProportional = 1.0
	border.borderRight = 4
	border.visible = params.useSearch

	-- Create the search input itself.
	local input = border:createTextInput({ id = tes3ui.registerID(params.id) })
	input.color = params.placeholderTextColor or tes3ui.getPalette("disabled_color")
	input.text = params.placeholderText or ""
	input.borderLeft = 5
	input.borderRight = 5
	input.borderTop = 2
	input.borderBottom = 4
	input.widget.eraseOnFirstKey = true
	input.disabled = not params.useSearch

	-- Set up the events to control text input control.
	input.consumeMouseEvents = false
	input:register("keyEnter", function(e)
		if (params.onSubmit) then
			params.onSubmit(e)
		end
	end)
	input:register("keyPress", function(e)
		local inputController = tes3.worldController.inputController
		if (inputController:isKeyDown(tes3.scanCode.tab)) then
			-- Prevent alt-tabbing from creating spacing.
			return
		elseif (inputController:isKeyDown(tes3.scanCode.backspace)) then
			if (inputController:isKeyDown(tes3.scanCode.leftAlt)) then
				input.text = '' -- Alt + Backspace = clearfilter /abot
			elseif input.text == params.placeholderText then
				-- Prevent backspacing into nothing.
				return
			end
		elseif (inputController:isKeyDown(tes3.scanCode.a)) then
			if (inputController:isKeyDown(tes3.scanCode.leftAlt)) then
				input.text = '' -- Alt + A = clearfilter /abot
			end
		end

		if (params.onPreUpdate) then
			if (params.onPreUpdate() == false) then
				return
			end
		end

		input:forwardEvent(e)

		input.color = params.textColor or tes3ui.getPalette("normal_color")
		if (params.onUpdate) then
			params.onUpdate(e)
		end
		input:updateLayout()
	end)

	-- search clear icon added
	local icon = border:createImage({ id = "UIEXP:SearchClearIcon", path = "icons/ui_exp/filter_reset.dds" })
	icon.imageScaleX = 0.6
	icon.imageScaleY = 0.6
	icon.borderLeft = 0
	icon.borderRight = 0
	icon.borderTop = 0
	icon.borderBottom = 0
	icon.borderAllSides = 0
	icon:register("mouseClick", function(e)
		input.text = '' --"Search by name..."
		input:forwardEvent(e)
		input.color = params.textColor or tes3ui.getPalette("normal_color")
		params.onUpdate(e)
		input:updateLayout()
	end)

	border:register("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)

	return { border = border, input = input }
end

----------------------------------------------------------------------------------------------------
-- Generic Filtering Module
----------------------------------------------------------------------------------------------------

local filter_functions = {}
local filter_metatable = { __index = filter_functions }

-- Adds a filter and all its associated data to the interface.
function filter_functions:addFilter(params)
	assert(params)
	assert(params.key)

	if (self.filters[params.key]) then
		error(string.format("Filter already contains key '%s'.", params.key))
	end

	self.filters[params.key] = params
	table.insert(self.filtersOrdered, params)
	table.insert(self.activeFilters, params.key)
end

function filter_functions:setFilterHidden(key, hidden)
	self.filters[key].hidden = hidden
	if (hidden) then
		table.removevalue(self.activeFilters, key)
	end
end

function filter_functions:setSearchBarUsage(state)
	self.useSearch = state
	if (self.searchBlock) then
		self.searchBlock.border.visible = state
		self.searchBlock.input.disabled = not state
	end
end

function filter_functions:setIconUsage(state)
	self.useIcons = state
	if (self.iconFiltersBlock) then
		self.iconFiltersBlock.visible = state
	end
	if (self.buttonFiltersBlock) then
		self.buttonFiltersBlock.visible = not state
	end
end

-- Sets both search text and filters.
function filter_functions:setFiltersExact(params)
	local params = params or {}

	self.searchText = params.text
	self.activeFilters = params.filters or {}

	if (self.searchText == "") then
		self.searchText = nil
	end

	if (params.filter) then
		self.activeFilters = { params.filter }
	end

	if (self.createSearchBar and self.searchText == nil and self.searchBlock ~= nil) then
		self.searchBlock.input.text = self.searchTextPlaceholder
		self.searchBlock.input.color = self.searchTextPlaceholderColor
	end

	if (#self.activeFilters == 0) then
		for key, filter in pairs(self.filters) do
			if (not filter.hidden) then
				table.insert(self.activeFilters, key)
			end
		end
	end

	self:updateFilterIcons()
	if (self.onFilterChanged) then
		self.onFilterChanged()
	end
end

-- Sets search text, but retains current filters.
function filter_functions:setFilterText(text)
	self:setFiltersExact({ text = text, filters = self.activeFilters })
end

function filter_functions:setFilter(key)
	self:setFiltersExact({ text = self.searchText, filter = key })
end

function filter_functions:toggleFilter(key)
	local filters = self.activeFilters
	if (table.find(filters, key)) then
		table.removevalue(filters, key)
	else
		table.insert(filters, key)
	end

	self:setFiltersExact({ text = self.searchText, filters = filters })
end

-- Clears any current search text and filters.
function filter_functions:clearFilter()
	self:setFiltersExact()
end

function filter_functions:triggerFilter(params)
	-- Search by name.
	if (self.searchText and params.text and not string.find(string.lower(params.text), self.searchText, 1, true)) then
		return false
	end

	-- Otherwise go through active filters.
	if (#self.filtersOrdered > 0) then
		for key, filter in pairs(self.filters) do
			if (filter.callback) then
				if (table.find(self.activeFilters, key) and filter.callback(params)) then
					return true
				end
			end
		end
	else
		return true
	end

	return false
end

function filter_functions:focusSearchBar()
	if (self.searchBlock) then
		tes3ui.acquireTextInput(self.searchBlock.input)
	end
end

function filter_functions:getSearchText()
	if (self.searchBlock) then
		local text = self.searchBlock.input.text
		if (text ~= "" and text ~= self.searchTextPlaceholder) then
			return text
		end
	end
end

function filter_functions:updateFilterIcons()
	for key, filter in pairs(self.filters) do
		if (table.find(self.activeFilters, key)) then
			if (filter.iconElement) then
				filter.iconElement.alpha = 1.0
				filter.iconElement.visible = not filter.hidden
				filter.iconElement:updateLayout()
			end
			if (filter.buttonElement) then
				filter.buttonElement.widget.state = 1
				filter.buttonElement.visible = not filter.hidden
				filter.buttonElement:updateLayout()
			end
		else
			if (filter.iconElement) then
				filter.iconElement.alpha = 0.5
				filter.iconElement.visible = not filter.hidden
				filter.iconElement:updateLayout()
			end
			if (filter.buttonElement) then
				filter.buttonElement.widget.state = 2
				filter.buttonElement.visible = not filter.hidden
				filter.buttonElement:updateLayout()
			end
		end
	end
end

function filter_functions:onClickFilter(filter)
	if (#self.activeFilters == 1 and self.activeFilters[1] == filter.key) then
		self:setFilter(nil)
	elseif (tes3.worldController.inputController:isKeyDown(42)) then
		self:toggleFilter(filter.key)
	else
		self:setFilter(filter.key)
	end
end

function filter_functions:onTooltip(filter)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = filter.tooltip.text })

	if (common.config.showHelpText and filter.tooltip.helpText) then
		local disabledPalette = tes3ui.getPalette("disabled_color")
		for _, text in pairs(filter.tooltip.helpText) do
			local helpText = tooltipBlock:createLabel({ text = text })
			helpText.color = disabledPalette
			helpText.borderTop = 6
		end

		local helpText = tooltipBlock:createLabel({ text = common.dictionary.helpTextDisableTip })
		helpText.color = disabledPalette
		helpText.borderTop = 6
	end
end

function filter_functions:createFilterIcon(filter)
	local icon = self.iconFiltersBlock:createImage({ id = string.format("UIEXP:FilterIcon:%s", filter.key), path = filter.icon })
	icon.imageScaleX = 0.6
	icon.imageScaleY = 0.6
	icon.borderLeft = 2
	icon.visible = not filter.hidden
	icon:register("mouseClick", function() self:onClickFilter(filter) end)
	icon:register("help", function() self:onTooltip(filter) end)
	filter.iconElement = icon
	return icon
end

function filter_functions:createFilterButton(filter)
	local button = self.buttonFiltersBlock:createButton({ id = string.format("UIEXP:FilterButton:%s", filter.key) })
	button.text = filter.buttonText
	button.borderLeft = 0
	button.borderRight = 4
	button.borderTop = 0
	button.borderBottom = 0
	button.borderAllSides = 0
	button.visible = not filter.hidden
	button:register("mouseClick", function() self:onClickFilter(filter) end)
	button:register("help", function() self:onTooltip(filter) end)
	filter.buttonElement = button
	return button
end

function filter_functions:createElements(parent)
	self.parentElement = parent

	parent:destroyChildren()

	-- Always create searchbars, even if they're going to be hidden.
	local searchBarParams = {
		parent = parent,
		id = "UIEXP:FiltersearchBlock",
		textColor = self.searchTextColor,
		placeholderText = self.searchTextPlaceholder,
		placeholderTextColor = self.searchTextPlaceholderColor,
		useSearch = self.useSearch,
		onUpdate = function(e)
			self:setFilterText(string.lower(e.source.text))
		end
	}
	if (self.onSearchTextPreUpdate) then
		searchBarParams.onPreUpdate = self.onSearchTextPreUpdate
	end
	self.searchBlock = common.createSearchBar(searchBarParams)

	-- Create icons for filtering.
	if (self.createIcons) then
		local block = parent:createThinBorder({})
		block.autoWidth = true
		block.autoHeight = true
		block.borderLeft = 0
		block.paddingTop = 2
		block.paddingBottom = 3
		block.paddingLeft = 2
		block.paddingRight = 3

		self.iconFiltersBlock = block
		block:register("destroy", function()
			self.iconFiltersBlock = nil
		end)

		for index, filter in pairs(self.filtersOrdered) do
			local icon = self:createFilterIcon(filter)
			if (index == 1) then
				icon.borderLeft = 0
			end
		end

		self.iconFiltersBlock.visible = self.useIcons
	end

	-- Create buttons for filtering.
	if (self.createButtons) then
		local block = parent:createBlock({})
		block.autoHeight = true
		block.autoWidth = true
		block.borderTop = 1

		self.buttonFiltersBlock = block
		block:register("destroy", function()
			self.buttonFiltersBlock = nil
		end)

		for _, filter in pairs(self.filtersOrdered) do
			self:createFilterButton(filter)
		end

		self.buttonFiltersBlock.visible = not self.useIcons
	end

	self:clearFilter()
end

common.allFilters = {}

function common.createFilterInterface(params)
	local filterData = {}

	filterData.createSearchBar = params.createSearchBar
	filterData.searchText = nil
	filterData.searchTextColor = params.searchTextColor or tes3ui.getPalette("normal_color")
	filterData.searchTextPlaceholder = params.searchTextPlaceholder or common.dictionary.searchByName
	filterData.searchTextPlaceholderColor = params.searchTextPlaceholderColor or tes3ui.getPalette("disabled_color")

	filterData.filters = {}
	filterData.activeFilters = {}
	filterData.filtersOrdered = {}

	filterData.useSearch = params.useSearch
	filterData.useIcons = params.useIcons
	filterData.createIcons = params.createIcons
	filterData.createButtons = params.createButtons

	filterData.onSearchTextPreUpdate = params.onSearchTextPreUpdate
	filterData.onFilterChanged = params.onFilterChanged
	filterData.extraData = params.extraData

	local filterInterface = setmetatable(filterData, filter_metatable)
	common.allFilters[params.filterName] = filterInterface
	return filterInterface
end

function common.setAllFiltersVisibility(visible)
	for _, filter in pairs(common.allFilters) do
		filter:setSearchBarUsage(visible)
		filter:clearFilter()
	end
end

----------------------------------------------------------------------------------------------------
-- Shared code for often-used filters.
----------------------------------------------------------------------------------------------------

function common.createStandardInventoryFilters(filterInterface)
	filterInterface:addFilter({
		key = "weapon",
		callback = function(e)
			local objectType = e.item.objectType
			return (objectType == tes3.objectType.weapon or objectType == tes3.objectType.ammunition)
		end,
		tooltip = {
			text = common.dictionary.filterWeaponsHelpDescription,
			helpText = common.dictionary.filterWeaponsHelpText,
		},
		icon = "icons/ui_exp/inventory_weapons.tga",
		buttonText = common.dictionary.filterWeaponsButtonName,
	})

	filterInterface:addFilter({
		key = "apparel",
		callback = function(e)
			local objectType = e.item.objectType
			return (objectType == tes3.objectType.armor or objectType == tes3.objectType.clothing)
		end,
		tooltip = {
			text = common.dictionary.filterApparelHelpDescription,
			helpText = common.dictionary.filterApparelHelpText,
		},
		icon = "icons/ui_exp/inventory_apparel.tga",
		buttonText = common.dictionary.filterApparelButtonName,
	})

	filterInterface:addFilter({
		key = "consumable",
		callback = function(e)
			local item = e.item
			local enchantment = item.enchantment
			return (
				item.objectType == tes3.objectType.alchemy or
				( enchantment and (enchantment.castType == tes3.enchantmentType.castOnce or enchantment.castType == tes3.enchantmentType.onUse) )
			)
		end,
		tooltip = {
			text = common.dictionary.filterConsumablesHelpDescription,
			helpText = common.dictionary.filterConsumablesHelpText,
		},
		icon = "icons/ui_exp/inventory_consumables.tga",
		buttonText = common.dictionary.filterConsumablesButtonName,
	})

	filterInterface:addFilter({
		key = "ingredient",
		callback = function(e)
			return (e.item.objectType == tes3.objectType.ingredient)
		end,
		tooltip = {
			text = common.dictionary.filterIngredientsHelpDescription,
			helpText = common.dictionary.filterIngredientsHelpText,
		},
		icon = "icons/ui_exp/inventory_ingredients.tga",
		buttonText = common.dictionary.filterIngredientsButtonName,
	})

	filterInterface:addFilter({
		key = "tools",
		callback = function(e)
			local objectType = e.item.objectType
			return (
				objectType == tes3.objectType.apparatus or
				objectType == tes3.objectType.probe or
				objectType == tes3.objectType.lockpick or
				objectType == tes3.objectType.repairItem or
				(objectType == tes3.objectType.miscItem and e.itemData and e.itemData.soul ~= nil)
			)
		end,
		tooltip = {
			text = common.dictionary.filterToolsHelpDescription,
			helpText = common.dictionary.filterToolsHelpText,
		},
		icon = "icons/ui_exp/inventory_tools.tga",
		buttonText = common.dictionary.filterToolsButtonName,
	})

	filterInterface:addFilter({
		key = "other",
		callback = function(e)
			local objectType = e.item.objectType
			local enchantment = e.item.enchantment
			return (
				(objectType == tes3.objectType.book and(enchantment == nil or
				(enchantment.castType ~= tes3.enchantmentType.castOnce and enchantment.castType ~= tes3.enchantmentType.onUse))) or
				objectType == tes3.objectType.light or
				(objectType == tes3.objectType.miscItem and (e.itemData and e.itemData.soul == nil or e.itemData == nil))
			)
		end,
		tooltip = {
			text = common.dictionary.filterOtherHelpDescription,
			helpText = common.dictionary.filterOtherHelpText,
		},
		icon = "icons/ui_exp/inventory_other.tga",
		buttonText = common.dictionary.filterOtherButtonName,
	})
end

----------------------------------------------------------------------------------------------------

return common
