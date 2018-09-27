
local GUI_ID_MenuBarter_bucket = tes3ui.registerID("MenuBarter_bucket")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Barter: Searching and filtering.
----------------------------------------------------------------------------------------------------

local barterFilters = common.creatFilterInterface({
	createSearchBar = true,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	onFilterChanged = tes3ui.updateBarterMenuTiles,
})
common.barterFilter = barterFilters

common.createStandardInventoryFilters(barterFilters)

local function onFilterBarterMenu(e)
	e.text = e.item.name
	e.filter = barterFilters:triggerFilter(e)
end
event.register("filterBarterMenu", onFilterBarterMenu )

local function onMenuBarterActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Create the filters.
	local buttonBlock = e.element:findChild(GUI_ID_MenuBarter_bucket).parent.children[1]
	barterFilters:createElements(buttonBlock)
end
event.register("uiActivated", onMenuBarterActivated, { filter = "MenuBarter" } )
