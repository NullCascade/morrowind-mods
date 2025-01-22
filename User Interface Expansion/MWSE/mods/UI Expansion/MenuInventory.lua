local GUI_ID_MenuBarter = tes3ui.registerID("MenuBarter")
local GUI_ID_MenuInventory_button_layout = tes3ui.registerID("MenuInventory_button_layout")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Inventory: Searching and filtering.
----------------------------------------------------------------------------------------------------

local inventoryFilters = common.createFilterInterface({
	filterName = "inventory",
	createSearchBar = true,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	useSearch = common.config.useSearch,
	onFilterChanged = tes3ui.updateInventoryTiles,
})

common.createStandardInventoryFilters(inventoryFilters)

inventoryFilters:addFilter({
	key = "tradable",
	callback = function(e)
		local serviceActor = tes3ui.getServiceActor()
		return serviceActor and tes3.checkMerchantTradesItem({ reference = serviceActor, item = e.item })
	end,
	tooltip = {
		text = common.i18n("filter.tradable.help.text"),
		helpText = common.i18n("filter.tradable.help.helpText"),
	},
	icon = "icons/ui_exp/inventory_tradable.tga",
	buttonText = common.i18n("filter.tradable.buttonName"),
	hidden = true,
})

--- Allow our filters to hide tiles in the inventory menu.
--- @param e filterInventoryEventData
local function onFilterInventory(e)
	e.text = e.item.name
	e.effects = e.item.enchantment and e.item.enchantment.effects
	e.filter = inventoryFilters:triggerFilter(e)
end
event.register("filterInventory", onFilterInventory)

--- Called when any MenuInventory item tile is clicked.
--- @param e tes3uiEventData
local function onInventoryTileClicked(e)
	-- Fire off an event when the tile is clicked for other modules to hook into.
	local tileData = e.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile") --- @type tes3inventoryTile

	local eventData = {
		element = tileData.element,
		tile = tileData,
		item = tileData.item,
		itemData = tileData.itemData,
		count = tileData.count,
	}
	local response = event.trigger("UIEX:InventoryTileClicked", eventData, { filter = eventData.item })
	if (response.block) then
		return false
	end
end

--- Claim mouse click events on item tiles.
--- @param e itemTileUpdatedEventData
local function onInventoryTileUpdated(e)
	e.element:registerBefore("mouseClick", onInventoryTileClicked)
end
event.register("itemTileUpdated", onInventoryTileUpdated, { filter = "MenuInventory" })

--- Create our changes for MenuInventory.
--- @param e uiActivatedEventData
local function onMenuInventoryActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Create our filters.
	local buttonBlock = e.element:findChild(GUI_ID_MenuInventory_button_layout)
	inventoryFilters:createElements(buttonBlock)

	-- Are we also showing the barter menu?
	local barterMenu = tes3ui.findMenu(GUI_ID_MenuBarter)
	inventoryFilters:setFilterHidden("tradable", (barterMenu == nil))
end
event.register("uiActivated", onMenuInventoryActivated, { filter = "MenuInventory" })

--- Update filters when entering menu mode.
local function onEnterMenuMode()
	inventoryFilters:setFilterHidden("tradable", true)

	if (common.config.alwaysClearFiltersOnOpen) then
		inventoryFilters:clearFilter()
	end

	if (common.config.autoSelectInput == "Inventory") then
		inventoryFilters:focusSearchBar()
	end
end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuContents" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })
