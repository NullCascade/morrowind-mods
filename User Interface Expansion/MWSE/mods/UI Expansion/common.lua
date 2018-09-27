local common = {}

----------------------------------------------------------------------------------------------------
-- UI Functions
----------------------------------------------------------------------------------------------------

function common.createSearchBar(params)
	local border = params.parent:createThinBorder({})
	border.autoWidth = true
	border.autoHeight = true
	border.widthProportional = 1.0

	-- Create the search input itself.
	local input = border:createTextInput({ id = tes3ui.registerID(params.id) })
	input.color = tes3ui.getPalette("disabled_color")
	input.text = params.placeholderText
	input.borderLeft = 5
	input.borderRight = 5
	input.borderTop = 2
	input.borderBottom = 4
	input.widget.eraseOnFirstKey = true
	input.widget.lengthLimit = 31

	-- Set up the events to control text input control.
	input.consumeMouseEvents = false
	input:register("keyPress", function(e)
		-- Prevent alt-tabbing from creating spacing.
		if (tes3.worldController.inputController:isKeyPressedThisFrame(15)) then
			return
		end

		input:forwardEvent(e)

		input.color = tes3ui.getPalette("normal_color")
		params.onUpdate(e)
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

	if (#self.activeFilters == 0) then
		for key, filter in pairs(self.filters) do
			if (not filter.hidden) then
				table.insert(self.activeFilters, key)
			end
		end
	end

	if (self.searchBlock and self.searchText == nil) then
		self.searchBlock.input.text = self.searchTextPlaceholder
		self.searchBlock.input.color = self.searchTextPlaceholderColor
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
	if (self.searchText and params.text and not string.find(string.lower(params.text), self.searchText)) then
		return false
	end

	-- Otherwise go through active filters.
	for key, filter in pairs(self.filters) do
		if (filter.callback) then
			if (table.find(self.activeFilters, key) and filter.callback(params)) then
				return true
			end
		end
	end

	return false
end

function filter_functions:focusSearchBar()
	if (self.searchBlock) then
		tes3ui.acquireTextInput(self.searchBlock.input)
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
		for index, text in pairs(filter.tooltip.helpText) do
			local helpText = tooltipBlock:createLabel({ text = text })
			helpText.color = disabledPalette
			helpText.borderTop = 6
		end

		local helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
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
	button.imageScaleX = 0.6
	button.imageScaleY = 0.6
	button.borderLeft = 4
	button.borderRight = 0
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

	-- Create our search bar if we are using one.
	if (self.createSearchBar) then
		self.searchBlock = common.createSearchBar({
			parent = parent,
			id = "UIEXP:FiltersearchBlock",
			placeholderText = self.searchTextPlaceholder,
			onUpdate = function(e)
				self:setFilterText(e.source.text)
			end
		})
	end

	-- Create icons for filtering.
	if (self.createIcons) then
		local block = parent:createThinBorder({})
		block.autoWidth = true
		block.autoHeight = true
		block.borderLeft = 4
		block.paddingTop = 2
		block.paddingBottom = 3
		block.paddingLeft = 2
		block.paddingRight = 3

		self.iconFiltersBlock = block
		block:register("destroy", function(e)
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
		block:register("destroy", function(e)
			self.buttonFiltersBlock = nil
		end)

		for index, filter in pairs(self.filtersOrdered) do
			self:createFilterButton(filter)
		end

		self.buttonFiltersBlock.visible = not self.useIcons
	end
end

function common.creatFilterInterface(params)
	local filterData = {}

	filterData.createSearchBar = params.createSearchBar
	filterData.searchText = nil
	filterData.searchTextPlaceholder = params.searchTextPlaceholder or "Search by name..."
	filterData.searchTextPlaceholderColor = params.searchTextPlaceholderColor or tes3ui.getPalette("disabled_color")

	filterData.filters = {}
	filterData.activeFilters = {}
	filterData.filtersOrdered = {}

	filterData.useIcons = params.useIcons
	filterData.createIcons = params.createIcons
	filterData.createButtons = params.createButtons
	
	filterData.onFilterChanged = params.onFilterChanged
	filterData.extraData = params.extraData

	return setmetatable(filterData, filter_metatable)
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
			text = "Filter to weapons",
			helpText = {
				"Click to filter to:",
				"- Ammunition",
				"- Weapons",
			},
		},
		icon = "icons/ui_exp/inventory_weapons.tga",
		buttonText = "Weapons",
	})
	
	filterInterface:addFilter({
		key = "apparel",
		callback = function(e)
			local objectType = e.item.objectType
			return (objectType == tes3.objectType.armor or objectType == tes3.objectType.clothing)
		end,
		tooltip = {
			text = "Filter to armor and clothing",
			helpText = {
				"Click to filter to:",
				"- Armor",
				"- Clothing",
			},
		},
		icon = "icons/ui_exp/inventory_apparel.tga",
		buttonText = "Apparel",
	})
	
	filterInterface:addFilter({
		key = "consumable",
		callback = function(e)
			local item = e.item
			local enchantment = item.enchantment
			return (
				item.objectType == tes3.objectType.alchemy or
				( enchantment and (enchantment.castType == 0 or enchantment.castType == 2) )
			)
		end,
		tooltip = {
			text = "Filter to consumables",
			helpText = {
				"Click to filter to:",
				"- Potions",
				"- Scrolls",
				"- On-use enchantments",
			},
		},
		icon = "icons/ui_exp/inventory_consumables.tga",
		buttonText = "Consumables",
	})
	
	filterInterface:addFilter({
		key = "ingredient",
		callback = function(e)
			return (e.item.objectType == tes3.objectType.ingredient)
		end,
		tooltip = {
			text = "Filter to ingredients",
			helpText = {
				"Click to filter to:",
				"- Ingredients",
			},
		},
		icon = "icons/ui_exp/inventory_ingredients.tga",
		buttonText = "Ingredients",
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
			text = "Filter to tools and soulgems",
			helpText = {
				"Click to filter to:",
				"- Apparatus",
				"- Lockpicks",
				"- Probes",
				"- Repair Tools",
				"- Soulgems",
			},
		},
		icon = "icons/ui_exp/inventory_tools.tga",
		buttonText = "Tools",
	})
	
	filterInterface:addFilter({
		key = "other",
		callback = function(e)
			local objectType = e.item.objectType
			local enchantment = e.item.enchantment
			return (
				(objectType == tes3.objectType.book and (enchantment == nil or (enchantment.castType ~= 0 and enchantment.castType ~= 2))) or
				objectType == tes3.objectType.light or
				(objectType == tes3.objectType.miscItem and (e.itemData and e.itemData.soul == nil or e.itemData == nil))
			)
		end,
		tooltip = {
			text = "Filter to other items",
			helpText = {
				"Click to filter to:",
				"- Books",
				"- Lights",
				"- Misc. Items",
			},
		},
		icon = "icons/ui_exp/inventory_other.tga",
		buttonText = "Other",
	})
end

----------------------------------------------------------------------------------------------------

return common
