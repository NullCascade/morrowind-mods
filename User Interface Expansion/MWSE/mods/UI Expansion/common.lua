local common = {}

----------------------------------------------------------------------------------------------------
-- Generic helper functions.
----------------------------------------------------------------------------------------------------

--- Performs a test on one or more keys.
--- @param keybind table<string,any>|number|string Keybind to test.
--- @return boolean
function common.complexKeybindTest(keybind)
	local keybindType = type(keybind)
	local inputController = tes3.worldController.inputController
	if (keybindType == "number") then
		return inputController:isKeyDown(keybind)
	elseif (keybindType == "table") then
		if (keybind.keyCode) then
			return mwse.mcm.testKeyBind(keybind)
		else
			for _, k in ipairs(keybind) do
				if (not common.complexKeybindTest(k)) then
					return false
				end
			end
			return true
		end
	elseif (keybindType == "string") then
		return inputController:keybindTest(tes3.keybind[keybind])
	end

	return false
end

--- Parses a color from either a table or a string.
--- @param color string|table
--- @return number[]
function common.getColor(color)
	local colorType = type(color)
	if (colorType == "table" and #color == 3) then
		return color
	elseif (colorType == "string") then
		return tes3ui.getPalette(color)
	end
end

--- Perhaps now-useless function to safely get the attribute at a given index. This should no longer be needed due to a
--- fix MWSE-side. We'll keep it here though out of pure laziness.
--- @param ingredient tes3ingredient
--- @param index number
--- @return number
function common.getIngredientEffectAttributeId(ingredient, index)
	local magicEffect = tes3.getMagicEffect(ingredient.effects[index])
	if (magicEffect.targetsAttributes) then
		return ingredient.effectAttributeIds[index]
	else
		return -1
	end
end

--- Perhaps now-useless function to safely get the skill at a given index. This should no longer be needed due to a fix
--- MWSE-side. We'll keep it here though out of pure laziness.
--- @param ingredient tes3ingredient
--- @param index number
--- @return number
function common.getIngredientEffectSkillId(ingredient, index)
	local magicEffect = tes3.getMagicEffect(ingredient.effects[index])
	if (magicEffect.targetsSkills) then
		return ingredient.effectSkillIds[index]
	else
		return -1
	end
end

function common.isTextInputActive()
	local wc = tes3.worldController
	if (not wc) then
		return false
	end

	local focus = wc.menuController.inputController.textInputFocus
	if (focus == nil) then
		return false
	end

	return focus.type == "textInput"
end

----------------------------------------------------------------------------------------------------
-- Keyboard-to-UI binding helpers.
----------------------------------------------------------------------------------------------------

local currentKeyboardBoundScrollBar = nil
local keyboardScrollBarParams = nil
local keyboardScrollBarNumberInput = nil

--- Key handling for when a scroll bar is in focus.
--- @param e keyDownEventData
local function onKeyDownForScrollBar(e)
	-- Don't do anything if we have an input focused.
	if (common.isTextInputActive()) then
		return
	end

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

--- Mouse wheel handling for scroll bars.
--- @param e mouseWheelEventData
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

--- Removes bindings to manage scrollbars.
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

--- Binds a slider to respect keyboard input. Only one slider can be hooked at a time.
function common.bindScrollBarToKeyboard(params)
	-- Get rid of any current binding if applicable.
	common.unbindScrollBarFromKeyboard()

	-- When this element is destroyed, clean up.
	params.element:registerBefore("destroy", common.unbindScrollBarFromKeyboard)

	-- Set up the events and variables we'll need later.
	event.register("keyDown", onKeyDownForScrollBar)
	event.register("mouseWheel", onMouseWheelForScrollBar)
	currentKeyboardBoundScrollBar = params.element
	keyboardScrollBarParams = params
	keyboardScrollBarNumberInput = 0
end

----------------------------------------------------------------------------------------------------
-- Load translation data
----------------------------------------------------------------------------------------------------

common.i18n = mwse.loadTranslations("UI Expansion")

----------------------------------------------------------------------------------------------------
-- UI Functions
----------------------------------------------------------------------------------------------------

--- Table parameters to `common.createSearchBar()`.
--- @class uiExpansion.common.createSearchBar.params
--- @field id string
--- @field onPreUpdate function
--- @field onSubmit function
--- @field onUpdate function
--- @field parent tes3uiElement
--- @field searchTextPlaceholder string
--- @field searchTextPlaceholderColor number[]
--- @field textColor number[]
--- @field useSearch boolean

--- @param e tes3uiEventData
local function onSearchBarPostKeyEnter(e)
	local params = e.source:getLuaData("params") --- @type uiExpansion.common.createSearchBar.params
	if (params.onSubmit) then
		params.onSubmit(e)
	end
end

--- Creates a search bar in a parent menu.
--- @param params uiExpansion.common.createSearchBar.params
--- @return table
function common.createSearchBar(params)
	local border = params.parent:createThinBorder()
	border.autoWidth = true
	border.autoHeight = true
	border.widthProportional = 1.0
	border.borderRight = 4
	border.visible = params.useSearch

	-- Create the search input itself.
	local input = border:createTextInput({
		id = params.id,
		placeholderText = params.searchTextPlaceholder or common.i18n("filter.searchByName"),
		placeholderTextColor = params.searchTextPlaceholderColor or tes3ui.getPalette("disabled_color"),
	})
	input.borderLeft = 5
	input.borderRight = 5 + 10
	input.borderTop = 2
	input.borderBottom = 4
	input.disabled = not params.useSearch

	-- Set up the events to control text input control.
	input.consumeMouseEvents = false
	input:registerAfter("keyEnter", onSearchBarPostKeyEnter)
	input:registerBefore("keyPress", function(e)
		local inputController = tes3.worldController.inputController

		-- Allow Alt+A to clear the filter.
		if (inputController:isKeyDown(tes3.scanCode.a) and inputController:isAltDown()) then
			input.text = ''
		end

		if (params.onPreUpdate) then
			if (params.onPreUpdate() == false) then
				return
			end
		end
	end)
	input:registerAfter("keyPress", function(e)
		input.color = params.textColor or tes3ui.getPalette("normal_color")
		if (params.onUpdate) then
			params.onUpdate(e)
		end
		input:updateLayout()
	end)

	-- search clear icon added
	local icon = border:createImage({ id = "UIEXP:SearchClearIcon", path = "icons/ui_exp/filter_reset.dds" })
	icon.imageScaleX = 0.5
	icon.imageScaleY = 0.5
	icon.absolutePosAlignX = 1.0
	icon.absolutePosAlignY = 0.5
	icon.borderRight = 4
	icon:registerAfter("mouseClick", function(e)
		input.text = '' -- "Search by name..."
	end)
	icon:registerAfter("mouseClick", function(e)
		input.color = params.textColor or tes3ui.getPalette("normal_color")
		params.onUpdate(e)
		input:updateLayout()
	end)

	border:registerAfter("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)

	params.input = input
	params.border = border
	params.icon = icon
	border:setLuaData("params", params)
	input:setLuaData("params", params)
	icon:setLuaData("params", params)

	return { border = border, input = input }
end

----------------------------------------------------------------------------------------------------
-- Generic Filtering Module
----------------------------------------------------------------------------------------------------

--- @class uiExFilterFunction
--- @field buttonFiltersBlock tes3uiElement
--- @field createButtons boolean
--- @field createIcons boolean
--- @field createSearchBar boolean
--- @field filters table
--- @field filtersOrdered table
--- @field onFilterChanged function
--- @field onSearchTextPreUpdate function
--- @field searchTextColor number[]
--- @field searchTextPlaceholder tes3uiElement
--- @field searchTextPlaceholderColor number[]
local uiExFilterFunction = {}
local uiExFilterFunctionMT = { __index = uiExFilterFunction }

--- Adds a filter and all its associated data to the interface.
--- @param params table
function uiExFilterFunction:addFilter(params)
	assert(params)
	assert(params.key)

	if (self.filters[params.key]) then
		error(string.format("Filter already contains key '%s'.", params.key))
	end

	self.filters[params.key] = params
	table.insert(self.filtersOrdered, params)
	table.insert(self.activeFilters, params.key)
end

--- Sets a filter as (un)hidden for a given key.
--- @param key string
--- @param hidden boolean
function uiExFilterFunction:setFilterHidden(key, hidden)
	self.filters[key].hidden = hidden
	if (hidden) then
		table.removevalue(self.activeFilters, key)
	end
end

--- Enables or disables search bars.
--- @param state boolean
function uiExFilterFunction:setSearchBarUsage(state)
	self.useSearch = state
	if (self.searchBlock) then
		self.searchBlock.border.visible = state
		self.searchBlock.input.disabled = not state
	end
end

---	Enables or disables compact icons.
---	@param state boolean
function uiExFilterFunction:setIconUsage(state)
	self.useIcons = state
	if (self.iconFiltersBlock) then
		self.iconFiltersBlock.visible = state
	end
	if (self.buttonFiltersBlock) then
		self.buttonFiltersBlock.visible = not state
	end
end

--- Sets both search text and filters.
--- @param params table?
function uiExFilterFunction:setFiltersExact(params)
	params = params or {}

	local previousSearchText = self.searchText
	self.searchText = params.text
	self.activeFilters = params.filters or {}

	if (self.searchText == "") then
		self.searchText = nil
	end

	if (self.searchText and previousSearchText and string.startswith(self.searchText, previousSearchText)) then
		-- Clear any passes so they get rechecked. Previous failures remain failures.
		for k, v in pairs(self.cachedEffectResults) do
			if (v == true) then
				self.cachedEffectResults[k] = nil
			end
		end
	else
		self.cachedEffectResults = {}
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
		self:onFilterChanged()
	end
end

--- Sets search text, but retains current filters.
--- @param text string
function uiExFilterFunction:setFilterText(text)
	self:setFiltersExact({ text = text, filters = self.activeFilters })
end

--- Sets the current filter.
--- @param key string
function uiExFilterFunction:setFilter(key)
	self:setFiltersExact({ text = self.searchText, filter = key })
end

--- Toggles a filter.
--- @param key string
function uiExFilterFunction:toggleFilter(key)
	local filters = self.activeFilters
	if (table.find(filters, key)) then
		table.removevalue(filters, key)
	else
		table.insert(filters, key)
	end

	self:setFiltersExact({ text = self.searchText, filters = filters })
end

--- Clears any current search text and filters.
function uiExFilterFunction:clearFilter()
	self:setFiltersExact()
end

--- Provides a filter with information and allows it to return if the filter allows the given information.
--- @param params table
--- @return boolean
function uiExFilterFunction:triggerFilter(params)
	return self:checkText(params) and self:checkFilters(params)
end

--- Checks to see if either the given text or the given effects match a search.
--- @param params table
--- @return boolean
function uiExFilterFunction:checkText(params)
	local searchText = self.searchText
	if (not searchText) then
		return true
	end

	-- Search by name.
	if (params.text and string.find(string.lower(params.text), searchText, 1, true)) then
		return true
	end

	-- Search by slot or type name.
	local item = params.item
	if (common.config.useSearchTypes) then
		if (item) then
			local slotOrTypeName = item.typeName or item.slotName
			if (slotOrTypeName) then
				if (string.find(string.lower(slotOrTypeName), searchText, 1, true)) then
					return true
				end
			end
		end
	end

	-- Search for contained soul.
	local itemData = params.itemData
	if (common.config.useSearchSouls) then
		if (item and item.isSoulGem and itemData and itemData.soul and string.find(string.lower(itemData.soul.name), searchText, 1, true)) then
			return true
		end
	end

	-- Search effects.
	if (common.config.useSearchEffects) then
		-- Rebundle ingredient effects.
		local effects = params.effects or {}
		if (item and item.objectType == tes3.objectType.ingredient) then
			for index, effectId in ipairs(item.effects) do
				if (effectId >= 0) then
					local object = tes3.getMagicEffect(effectId)
					effects[index] = {
						id = effectId,
						object = object,
						attribute = item.effectAttributeIds[index],
						skill = item.effectSkillIds[index],
					}
				end
			end
		end

		for _, effect in ipairs(effects) do
			-- Figure out a unique key for the effect.
			local effectObject = effect.object
			if (effectObject) then
				local cacheToken = effect.id
				if (effectObject.targetsAttributes) then
					cacheToken = cacheToken + (effect.attribute / 1000)
				elseif (effectObject.targetsSkills) then
					cacheToken = cacheToken + (effect.skill / 1000)
				end

				local cachedResult = self.cachedEffectResults[cacheToken];
				if (cachedResult == true) then
					return true
				elseif (cachedResult == nil) then
					local effectSearchResult = false
					local effectName = tes3.getMagicEffectName({ effect = effect.id, attribute = effect.attribute, skill = effect.skill })
					if (string.find(string.lower(effectName), searchText, 1, true)) then
						effectSearchResult = true
					end

					self.cachedEffectResults[cacheToken] = effectSearchResult
					if (effectSearchResult) then
						return true
					end
				end
			end
		end
	end

	return false
end

--- Checks to see if any active filters (i.e. type buttons) reject our search.
--- @param params table
--- @return boolean
function uiExFilterFunction:checkFilters(params)
	if (#self.filtersOrdered == 0) then
		return true
	end

	for key, filter in pairs(self.filters) do
		if (filter.callback) then
			if (table.find(self.activeFilters, key) and filter.callback(params)) then
				return true
			end
		end
	end

	return false
end

--- Forces focus onto the search box.
function uiExFilterFunction:focusSearchBar()
	if (self.searchBlock) then
		tes3ui.acquireTextInput(self.searchBlock.input)
	end
end

--- Returns the current search text.
--- @return string|nil
function uiExFilterFunction:getSearchText()
	if (self.searchBlock) then
		local text = self.searchBlock.input.text
		if (text ~= "" and text ~= self.searchTextPlaceholder) then
			return text
		end
	end
end

--- Updates filter icons, showing/hiding and setting alphas as needed.
function uiExFilterFunction:updateFilterIcons()
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

--- Callback for when a filter is clicked.
--- @param filter table
function uiExFilterFunction:onClickFilter(filter)
	if (#self.activeFilters == 1 and self.activeFilters[1] == filter.key) then
		self:setFilter(nil)
	elseif (tes3.worldController.inputController:isKeyDown(42)) then
		self:toggleFilter(filter.key)
	else
		self:setFilter(filter.key)
	end
end

--- Shows a tooltip for a given filter.
--- @param filter table
function uiExFilterFunction:onTooltip(filter)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = filter.tooltip.text })

	if (common.config.showHelpText and filter.tooltip.helpText) then
		local disabledPalette = tes3ui.getPalette("disabled_color")
		for _, text in pairs(string.split(filter.tooltip.helpText, "\n")) do
			local helpText = tooltipBlock:createLabel({ text = text })
			helpText.color = disabledPalette
			helpText.borderTop = 6
		end

		local helpText = tooltipBlock:createLabel({ text = common.i18n("filter.helpTextDisableTip") })
		helpText.color = disabledPalette
		helpText.borderTop = 6
	end
end

--- Creates a filter icon for a filter.
--- @param filter table
--- @return tes3uiElement
function uiExFilterFunction:createFilterIcon(filter)
	local icon = self.iconFiltersBlock:createImage({
		id = string.format("UIEXP:FilterIcon:%s", filter.key),
		path = filter.icon,
	})
	icon.imageScaleX = 0.6
	icon.imageScaleY = 0.6
	icon.borderLeft = 2
	icon.visible = not filter.hidden
	icon:register("mouseClick", function()
		self:onClickFilter(filter)
	end)
	icon:register("help", function()
		self:onTooltip(filter)
	end)
	filter.iconElement = icon
	return icon
end

--- Creates a button for a filter.
--- @param filter table
--- @return tes3uiElement
function uiExFilterFunction:createFilterButton(filter)
	local button = self.buttonFiltersBlock:createButton({ id = string.format("UIEXP:FilterButton:%s", filter.key) })
	button.text = filter.buttonText
	button.borderLeft = 0
	button.borderRight = 4
	button.borderTop = 0
	button.borderBottom = 0
	button.borderAllSides = 0
	button.visible = not filter.hidden
	button:register("mouseClick", function()
		self:onClickFilter(filter)
	end)
	button:register("help", function()
		self:onTooltip(filter)
	end)
	filter.buttonElement = button
	return button
end

--- Creates elements for a given parent block.
--- @param parent tes3uiElement
function uiExFilterFunction:createElements(parent)
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
		end,
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
		block:registerBefore("destroy", function()
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
		block:registerBefore("destroy", function()
			self.buttonFiltersBlock = nil
		end)

		for _, filter in pairs(self.filtersOrdered) do
			self:createFilterButton(filter)
		end

		self.buttonFiltersBlock.visible = not self.useIcons
	end

	self:clearFilter()
end

--- A list of all filters.
--- @type table<string, uiExFilterFunction>
common.allFilters = {}

--- Creates a filter interface.
--- @param params table
--- @return uiExFilterFunction
function common.createFilterInterface(params)
	--- @type uiExFilterFunction
	local filterData = {}

	filterData.createSearchBar = params.createSearchBar
	filterData.searchText = nil
	filterData.searchTextColor = params.searchTextColor or tes3ui.getPalette("normal_color")
	filterData.searchTextPlaceholder = params.searchTextPlaceholder or common.i18n("filter.searchByName")
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

	local filterInterface = setmetatable(filterData, uiExFilterFunctionMT)
	common.allFilters[params.filterName] = filterInterface
	return filterInterface
end

--- Sets the visibility for all filters.
--- @param visible boolean
function common.setAllFiltersVisibility(visible)
	for _, filter in pairs(common.allFilters) do
		filter:setSearchBarUsage(visible)
		filter:clearFilter()
	end
end

----------------------------------------------------------------------------------------------------
-- Shared code for often-used filters.
----------------------------------------------------------------------------------------------------

--- Creates standard filters common for inventory menus (inventory, barter, contents).
--- @param filterInterface uiExFilterFunction
function common.createStandardInventoryFilters(filterInterface)
	filterInterface:addFilter({
		key = "weapon",
		callback = function(e)
			local objectType = e.item.objectType
			return (objectType == tes3.objectType.weapon or objectType == tes3.objectType.ammunition)
		end,
		tooltip = {
			text = common.i18n("filter.weapons.help.text"),
			helpText = common.i18n("filter.weapons.help.helpText"),
		},
		icon = "icons/ui_exp/inventory_weapons.tga",
		buttonText = common.i18n("filter.weapons.buttonName"),
	})

	filterInterface:addFilter({
		key = "apparel",
		callback = function(e)
			local objectType = e.item.objectType
			return (objectType == tes3.objectType.armor or objectType == tes3.objectType.clothing)
		end,
		tooltip = {
			text = common.i18n("filter.apparel.helpDescription"),
			helpText = common.i18n("filter.apparel.helpText"),
		},
		icon = "icons/ui_exp/inventory_apparel.tga",
		buttonText = common.i18n("filter.apparel.buttonName"),
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
			text = common.i18n("filter.consumables.help.text"),
			helpText = common.i18n("filter.consumables.help.helpText"),
		},
		icon = "icons/ui_exp/inventory_consumables.tga",
		buttonText = common.i18n("filter.consumables.buttonName"),
	})

	filterInterface:addFilter({
		key = "ingredient",
		callback = function(e)
			return (e.item.objectType == tes3.objectType.ingredient)
		end,
		tooltip = {
			text = common.i18n("filter.ingredients.help.text"),
			helpText = common.i18n("filter.ingredients.help.helpText"),
		},
		icon = "icons/ui_exp/inventory_ingredients.tga",
		buttonText = common.i18n("filter.ingredients.buttonName"),
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
				(e.item.isSoulGem and e.itemData and e.itemData.soul)
			)
		end,
		tooltip = {
			text = common.i18n("filter.tools.help.text"),
			helpText = common.i18n("filter.tools.help.helpText"),
		},
		icon = "icons/ui_exp/inventory_tools.tga",
		buttonText = common.i18n("filter.tools.buttonName"),
	})

	filterInterface:addFilter({
		key = "other",
		callback = function(e)
			local objectType = e.item.objectType
			local enchantment = e.item.enchantment
			return (
				(objectType == tes3.objectType.book and (enchantment == nil or (enchantment.castType ~= tes3.enchantmentType.castOnce and enchantment.castType ~= tes3.enchantmentType.onUse))) or
				objectType == tes3.objectType.light or
				(e.item.objectType == tes3.objectType.miscItem and not (e.item.isSoulGem and e.itemData and e.itemData.soul))
			)
		end,
		tooltip = {
			text = common.i18n("filter.other.help.text"),
			helpText = common.i18n("filter.other.help.helpText"),
		},
		icon = "icons/ui_exp/inventory_other.tga",
		buttonText = common.i18n("filter.other.buttonName"),
	})
end

----------------------------------------------------------------------------------------------------

return common
