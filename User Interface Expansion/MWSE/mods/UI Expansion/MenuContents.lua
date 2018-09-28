
local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")
local GUI_ID_MenuContents_bucket = tes3ui.registerID("MenuContents_bucket")
local GUI_ID_MenuContents_takeallbutton = tes3ui.registerID("MenuContents_takeallbutton")
local GUI_ID_MenuContents_removebutton = tes3ui.registerID("MenuContents_removebutton")
local GUI_ID_MenuContents_closebutton = tes3ui.registerID("MenuContents_closebutton")

local common = require("UI Expansion.common")

local InputController = tes3.worldController.inputController

----------------------------------------------------------------------------------------------------
-- Contents: Searching and filtering.
----------------------------------------------------------------------------------------------------

local function onSearchTextPreUpdate(e)
	if (common.contentsFilter:getSearchText() == nil and InputController:keybindTest(tes3.keybind.activate, tes3.keyTransition.down)) then
		common.contentsFilter:clearFilter()
		tes3ui.leaveMenuMode()
		return false
	end
end

local contentsFilters = common.creatFilterInterface({
	createSearchBar = true,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	onFilterChanged = tes3ui.updateContentsMenuTiles,
	onSearchTextPreUpdate = onSearchTextPreUpdate,
})
common.contentsFilter = contentsFilters

common.createStandardInventoryFilters(contentsFilters)

local function onFilterContentsMenu(e)
	e.text = e.item.name
	e.filter = contentsFilters:triggerFilter(e)
end
event.register("filterContentsMenu", onFilterContentsMenu )

local function clearFilterBeforeTrigger(e)
	contentsFilters:clearFilter()
	e.source:forwardEvent(e)
end

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

	contentsMenu:register("destroy", clearFilterBeforeTrigger)
	contentsMenu:findChild(GUI_ID_MenuContents_takeallbutton):register("mouseClick", clearFilterBeforeTrigger)
	contentsMenu:findChild(GUI_ID_MenuContents_removebutton):register("mouseClick", clearFilterBeforeTrigger)
	contentsMenu:findChild(GUI_ID_MenuContents_closebutton):register("mouseClick", clearFilterBeforeTrigger)

	-- Create the filters.
	contentsFilters:createElements(filterBlock)

	-- Focus the filter search bar.
	contentsFilters:focusSearchBar()
end
event.register("uiActivated", onMenuContentsActivated, { filter = "MenuContents" } )
