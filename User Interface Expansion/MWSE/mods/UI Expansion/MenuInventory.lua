
local GUI_ID_MenuBarter = tes3ui.registerID("MenuBarter")
local GUI_ID_MenuInventory_button_layout = tes3ui.registerID("MenuInventory_button_layout")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Inventory: Searching and filtering.
----------------------------------------------------------------------------------------------------

local inventoryFilters = common.createFilterInterface({
	createSearchBar = true,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	onFilterChanged = tes3ui.updateInventoryTiles,
})
common.inventoryFilter = inventoryFilters

common.createStandardInventoryFilters(inventoryFilters)

local currentMerchant

inventoryFilters:addFilter({
	key = "tradable",
	callback = function(e)
		return tes3.checkMerchantTradesItem({ reference = currentMerchant, item = e.item })
	end,
	tooltip = {
		text = "Filter to sellable items",
		helpText = {
			"Click to filter to:",
			"- Items the merchant will buy",
		},
	},
	icon = "icons/ui_exp/inventory_tradable.tga",
	buttonText = "Tradable",
	hidden = true,
})

local function onFilterInventory(e)
	e.text = e.item.name
	e.filter = inventoryFilters:triggerFilter(e)
end
event.register("filterInventory", onFilterInventory )

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
	if (barterMenu) then
		currentMerchant = tes3ui.getServiceActor()
	else
		currentMerchant = nil
	end
end
event.register("uiActivated", onMenuInventoryActivated, { filter = "MenuInventory" } )

local function onMenuBarterActivated(e)
	currentMerchant = tes3ui.getServiceActor()
end
event.register("uiActivated", onMenuBarterActivated, { filter = "MenuBarter" } )

local function onEnterMenuMode(e)
	inventoryFilters:setFilterHidden("tradable", true)
	inventoryFilters:clearFilter()
	
	if (common.config.autoSelectInput == "Inventory") then
		inventoryFilters:focusSearchBar()
	end
end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })
