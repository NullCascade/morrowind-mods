
local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")
local GUI_ID_MenuContents_bucket = tes3ui.registerID("MenuContents_bucket")
local GUI_ID_MenuContents_takeallbutton = tes3ui.registerID("MenuContents_takeallbutton")
local GUI_ID_MenuContents_removebutton = tes3ui.registerID("MenuContents_removebutton")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Contents: Searching and filtering.
----------------------------------------------------------------------------------------------------

local function onFilterChanged(e)
	-- Re-draw inventory tiles.
	tes3ui.updateContentsMenuTiles()

	-- Set the take all button text depending on context.
	if (common.config.takeFilteredItems) then
		local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
		local takeAllButton = contentsMenu:findChild(GUI_ID_MenuContents_takeallbutton)
		if (common.contentsFilter.searchText == nil and #common.contentsFilter.activeFilters == #common.contentsFilter.filtersOrdered) then
			takeAllButton.text = "Take All"
		else
			takeAllButton.text = "Take Filtered"
		end
	end
end

local contentsFilters = common.creatFilterInterface({
	createSearchBar = true,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	onFilterChanged = onFilterChanged,
})
common.contentsFilter = contentsFilters

common.createStandardInventoryFilters(contentsFilters)

local function onFilterContentsMenu(e)
	e.text = e.item.name
	e.filter = contentsFilters:triggerFilter(e)
end
event.register("filterContentsMenu", onFilterContentsMenu )

local function onMenuContentsActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Add a new block in the right place.
	local contentsMenu = e.element
	local parentBlock = contentsMenu:findChild(GUI_ID_MenuContents_bucket).parent
	local filterBlock = parentBlock:createBlock({ id = "UIEXP:ContentsMenu:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4
	parentBlock:reorderChildren(0, -1, 1)

	-- Clear filters between viewings.
	contentsMenu:register("destroy", function(e)
		contentsFilters:clearFilter()
		e.source:forwardEvent(e)
	end)

	-- Clear filters and refresh UI before taking all.
	contentsMenu:findChild(GUI_ID_MenuContents_takeallbutton):register("mouseClick", function(e)
		if (not common.config.takeFilteredItems) then
			contentsFilters:clearFilter()
		end
		e.source:forwardEvent(e)
	end)

	-- Clear filters and refresh UI before disposing of corpse.
	contentsMenu:findChild(GUI_ID_MenuContents_removebutton):register("mouseClick", function(e)
		contentsFilters:clearFilter()
		e.source:forwardEvent(e)
	end)

	-- Create the filters.
	contentsFilters:createElements(filterBlock)

	-- Focus the filter search bar.
	contentsFilters:focusSearchBar()
end
event.register("uiActivated", onMenuContentsActivated, { filter = "MenuContents" } )
