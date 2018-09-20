
local GUI_ID_MenuInventory = tes3ui.registerID("MenuInventory")
local GUI_ID_MenuInventory_button_layout = tes3ui.registerID("MenuInventory_button_layout")

local GUI_ID_UIEXP_InventoryMenu_IconFilters = tes3ui.registerID("UIEXP_InventoryMenu_IconFilters")
local GUI_ID_UIEXP_InventoryMenu_ButtonFilters = tes3ui.registerID("UIEXP_InventoryMenu_ButtonFilters")

local GUI_Palette_Active = tes3ui.getPalette("active_color")
local GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")

local common = require("UI Expansion.common")

InputController = tes3.worldController.inputController

----------------------------------------------------------------------------------------------------
-- Inventory: Searching, sorting, and filtering.
----------------------------------------------------------------------------------------------------

local inventorySearchText = nil

local inventoryFilter = {
	["all"] = 0,
	["weapon"] = 1,
	["apparel"] = 2,
	["consumable"] = 3,
	["ingredient"] = 4,
	["tools"] = 5,
	["other"] = 6,
}

local inventoryActiveFilters = { [inventoryFilter.all] = true }

local inventoryFilterCallbacks = {}

function inventoryFilterCallbacks.all(e)
	return true
end

function inventoryFilterCallbacks.weapon(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.weapon or objectType == tes3.objectType.ammunition)
end

function inventoryFilterCallbacks.apparel(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.armor or objectType == tes3.objectType.clothing)
end

function inventoryFilterCallbacks.consumable(e)
	local objectType = e.item.objectType
	local enchantment = e.item.enchantment
	return (
		objectType == tes3.objectType.alchemy or
		( enchantment and (enchantment.castType == 0 or enchantment.castType == 2) )
	)
end

function inventoryFilterCallbacks.ingredient(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.ingredient)
end

function inventoryFilterCallbacks.tools(e)
	local objectType = e.item.objectType
	return (
		objectType == tes3.objectType.apparatus or 
		objectType == tes3.objectType.probe or 
		objectType == tes3.objectType.lockpick or 
		objectType == tes3.objectType.repairItem or
		(objectType == tes3.objectType.miscItem and e.itemData and e.itemData.soul ~= nil)
	)
end

function inventoryFilterCallbacks.other(e)
	local objectType = e.item.objectType
	local enchantment = e.item.enchantment
	return (
		(objectType == tes3.objectType.book and (enchantment == nil or (enchantment.castType ~= 0 and enchantment.castType ~= 2))) or
		objectType == tes3.objectType.light or
		(objectType == tes3.objectType.miscItem and (e.itemData and e.itemData.soul == nil or e.itemData == nil))
	)
end

local function updateInventoryFilterIcons()
	local menu = tes3ui.findMenu(GUI_ID_MenuInventory)
	local filtersBlock = menu:findChild(GUI_ID_UIEXP_InventoryMenu_IconFilters)
	local filtersChildren = filtersBlock.children
	local doAll = inventoryActiveFilters[inventoryFilter.all]
	for _, element in pairs(filtersChildren) do
		if (doAll) then
			element.alpha = 1.0
		else
			local id = element:getPropertyInt("UIEXP:Category")
			if (inventoryActiveFilters[id]) then
				element.alpha = 1.0
			else
				element.alpha = 0.5
			end
		end
		element:updateLayout()
	end
end

local function onInventoryFilterClick(e)
	local icon = e.source
	local id = icon:getPropertyInt("UIEXP:Category")
	local key = table.find(inventoryFilter, id)

	-- If this is the only filter active, reset to show all.
	local activeFilterCount = 0
	local activeFilter = nil
	for key, id in pairs(inventoryFilter) do
		if (inventoryActiveFilters[id]) then
			activeFilter = id
			activeFilterCount = activeFilterCount + 1
		end
	end
	if (activeFilterCount == 1 and activeFilter == id) then
		inventoryActiveFilters = { [inventoryFilter.all] = true }
		updateInventoryFilterIcons()
		tes3ui.updateInventoryTiles()
		return
	end

	-- If shift is pressed, toggle the element.
	if (InputController:isKeyDown(42)) then
		if (inventoryActiveFilters[inventoryFilter.all]) then
			-- No filters. Flip them all on, then turn off the one that was clicked.
			inventoryActiveFilters = {}
			for key, id in pairs(inventoryFilter) do
				inventoryActiveFilters[id] = true
			end
			inventoryActiveFilters[id] = nil
		elseif (inventoryActiveFilters[id]) then
			-- Some filters, disable this one.
			inventoryActiveFilters[id] = nil
		else
			-- Some filters, enable this one.
			inventoryActiveFilters[id] = true
		end

		-- We no longer use all filters at this point. But, check if we can optimize to.
		inventoryActiveFilters[inventoryFilter.all] = nil
		if (table.size(inventoryActiveFilters) >= table.size(inventoryFilter) - 1) then
			inventoryActiveFilters = { [inventoryFilter.all] = true }
		end
	else
		inventoryActiveFilters = { [id] = true }
		inventoryActiveFilters[inventoryFilter.all] = nil
	end

	updateInventoryFilterIcons()
	tes3ui.updateInventoryTiles()
end

local inventoryTooltipCallbacks = {}

function inventoryTooltipCallbacks.weapon(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to weapons" })

	if (common.config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Ammunition" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Weapons" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.apparel(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to armor and clothing" })

	if (common.config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Armor" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Clothing" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.consumable(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to consumables" })

	if (common.config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Potions" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Scrolls" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- On-use enchantments" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.ingredient(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to ingredients" })

	if (common.config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Ingredients" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.tools(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to tools and soulgems" })

	if (common.config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Apparatus" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Lockpicks" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Probes" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Repair Tools" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Soulgems" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.other(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to other items" })

	if (common.config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Books" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Lights" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Misc. Items" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

local function onInventoryFilterTooltip(e)
	local id = e.source:getPropertyInt("UIEXP:Category")
	local key = table.find(inventoryFilter, id)
	inventoryTooltipCallbacks[key](e)
end

local function filterInventory(e)
	-- Search by name.
	if (inventorySearchText and not string.find(string.lower(e.item.name), inventorySearchText)) then
		e.filter = false
		return
	end

	-- Otherwise go through active filters.
	for key, id in pairs(inventoryFilter) do
		if (not e.filter and inventoryActiveFilters[id]) then
			if (inventoryFilterCallbacks[key](e)) then
				e.filter = true
				return
			end
		end
	end

	e.filter = false
	return
end
event.register("filterInventory", filterInventory )

local function OnMenuInventoryActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local buttonBlock = e.element:findChild(GUI_ID_MenuInventory_button_layout)

	-- Start off by nuking our slate clean.
	buttonBlock:destroyChildren()

	-- Create search bar.
	common.createSearchBar({
		parent = buttonBlock,
		id = "UIEXP:InventoryMenu:SearchInput",
		placeholderText = "Search by name...",
		onUpdate = function(e)
			inventorySearchText = e.source.text
			if (inventorySearchText == "") then
				inventorySearchText = nil
			end
			tes3ui.updateInventoryTiles()
		end
	})

	-- Create icons for filtering.
	do
		local border = buttonBlock:createThinBorder({ id = GUI_ID_UIEXP_InventoryMenu_IconFilters })
		border.autoWidth = true
		border.autoHeight = true
		border.borderLeft = 4
		border.paddingTop = 3
		border.paddingBottom = 3
		border.paddingLeft = 3
		border.paddingRight = 3

		local function createFilterButton(e)
			local button = border:createImage({ path = e.icon })
			button.imageScaleX = 0.6
			button.imageScaleY = 0.6
			button.borderLeft = 2
			button:setPropertyInt("UIEXP:Category", inventoryFilter[e.key])
			button:register("mouseClick", onInventoryFilterClick)
			button:register("help", onInventoryFilterTooltip)
			return button
		end
		createFilterButton({ key = "weapon", icon = "icons/ui_exp/inventory_weapons.tga" }).borderLeft = 0
		createFilterButton({ key = "apparel", icon = "icons/ui_exp/inventory_apparel.tga" })
		createFilterButton({ key = "consumable", icon = "icons/ui_exp/inventory_consumables.tga" })
		createFilterButton({ key = "ingredient", icon = "icons/ui_exp/inventory_ingredients.tga" })
		createFilterButton({ key = "tools", icon = "icons/ui_exp/inventory_tools.tga" })
		createFilterButton({ key = "other", icon = "icons/ui_exp/inventory_other.tga" })
		
		border.visible = not common.config.useInventoryTextButtons
	end

	-- Create buttons for filtering.
	do
		local buttonFilterBlock = buttonBlock:createBlock({ id = GUI_ID_UIEXP_InventoryMenu_ButtonFilters })
		buttonFilterBlock.autoHeight = true
		buttonFilterBlock.autoWidth = true
		buttonFilterBlock.borderTop = 1

		local function createFilterButton(e)
			local button = buttonFilterBlock:createButton({})
			button.text = e.text
			button.imageScaleX = 0.6
			button.imageScaleY = 0.6
			button.borderLeft = 4
			button.borderRight = 0
			button.borderTop = 0
			button.borderBottom = 0
			button.borderAllSides = 0
			button:setPropertyInt("UIEXP:Category", inventoryFilter[e.key])
			button:register("mouseClick", onInventoryFilterClick)
			button:register("help", onInventoryFilterTooltip)
			return button
		end
		createFilterButton({ key = "weapon", text = "Weapons" })
		createFilterButton({ key = "apparel", text = "Apparel" })
		createFilterButton({ key = "consumable", text = "Consumables" })
		createFilterButton({ key = "ingredient", text = "Ingredients" })
		createFilterButton({ key = "tools", text = "Tools" })
		createFilterButton({ key = "other", text = "Other" })

		buttonFilterBlock.visible = common.config.useInventoryTextButtons
	end
end
event.register("uiActivated", OnMenuInventoryActivated, { filter = "MenuInventory" } )

local function onEnterMenuMode(e)
    -- Filter criteria.
    inventorySearchText = nil
    inventoryActiveFilters = { [inventoryFilter.all] = true }

    -- Reset filter text.
    local menu = tes3ui.findMenu(GUI_ID_MenuInventory)
    local input = menu:findChild(tes3ui.registerID("UIEXP:InventoryMenu:SearchInput"))
    input.text = "Search by name..."
    input.color = GUI_Palette_Disabled

    -- Reset GUI elements.
    updateInventoryFilterIcons()
    tes3ui.updateInventoryTiles()
end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })
