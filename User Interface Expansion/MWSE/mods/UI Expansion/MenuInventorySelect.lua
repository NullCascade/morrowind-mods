
local GUI_ID_MenuInventorySelect_prompt = tes3ui.registerID("MenuInventorySelect_prompt")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Generic filter cases
----------------------------------------------------------------------------------------------------

local genericFilter = common.createFilterInterface({
	filterName = "inventorySelect",
	createSearchBar = true,
	createIcons = true,
	createButtons = false,
	useIcons = true,
	useSearch = common.config.useSearch,
	onFilterChanged = tes3ui.updateInventorySelectTiles,
})

common.createStandardInventoryFilters(genericFilter)

----------------------------------------------------------------------------------------------------
-- Generic filter case w/o icons.
----------------------------------------------------------------------------------------------------

local genericFilterNoIcons = common.createFilterInterface({
	filterName = "inventorySelectNoIcons",
	createSearchBar = true,
	createIcons = false,
	createButtons = false,
	useIcons = false,
	useSearch = common.config.useSearch,
	onFilterChanged = tes3ui.updateInventorySelectTiles,
})

----------------------------------------------------------------------------------------------------
-- Inventory Select: Searching and advanced filtering.
----------------------------------------------------------------------------------------------------

local currentFilter = nil

local function onFilterInventorySelect(e)
	if (currentFilter) then
		e.text = e.item.name
		if (not currentFilter:triggerFilter(e)) then
			e.filter = false
		end
	end
end
event.register("filterInventorySelect", onFilterInventorySelect )

local inventorySelectTypeFilterMap = {
	["alembic"] = genericFilterNoIcons,
	["calcinator"] = genericFilterNoIcons,
	["ingredient"] = genericFilterNoIcons,
	["mortar"] = genericFilterNoIcons,
	["retort"] = genericFilterNoIcons,
	["soulGemFilled"] = genericFilterNoIcons,
}
common.inventorySelectTypeFilterMap = inventorySelectTypeFilterMap

local function onMenuInventorySelectActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Create a home for our filter buttons, and reposition it.
	local inventorySelectPane = e.element:findChild(GUI_ID_MenuInventorySelect_prompt).parent
	local filterBlock = inventorySelectPane:createBlock({ id = "UIEXP:InventorySelect:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4
	inventorySelectPane:reorderChildren(1, -1, 1)

	-- Don't carry the filter over between sessions.
	filterBlock:register("destroy", function() currentFilter = nil end)

	-- Change filtering options based on what menu we're specifically looking at.
	currentFilter = inventorySelectTypeFilterMap[tes3ui.getInventorySelectType()] or genericFilter
	currentFilter:createElements(filterBlock)
	currentFilter:focusSearchBar()
end
event.register("uiActivated", onMenuInventorySelectActivated, { filter = "MenuInventorySelect" } )
