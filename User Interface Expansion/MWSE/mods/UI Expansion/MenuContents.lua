
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

local function onSearchTextPreUpdate()
	-- Ctrl+Space (default) takes all.
	if (common.complexKeybindTest(common.config.keybindTakeAll)) then
		local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
		local takeAllButton = contentsMenu:findChild(GUI_ID_MenuContents_takeallbutton)
		takeAllButton:triggerEvent("mouseClick")
		return false
	-- Space (when no text) closes.
	elseif (common.contentsFilter:getSearchText() == nil and common.complexKeybindTest(common.config.keybindClose)) then
		tes3ui.leaveMenuMode()
		return false
	end
end

local function onFilterChanged()
	if (common.config.takeFilteredItems) then
		local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
		local takeAllButton = contentsMenu:findChild(GUI_ID_MenuContents_takeallbutton)
		local contentsFilter = common.contentsFilter
		if (contentsFilter.searchText ~= nil or #contentsFilter.filtersOrdered ~= #contentsFilter.activeFilters) then
			takeAllButton.text = "Take Filtered"
		else
			takeAllButton.text = "Take All"
		end
	end
	tes3ui.updateContentsMenuTiles()
end

local contentsFilters = common.createFilterInterface({
	createSearchBar = common.config.useSearch,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	onFilterChanged = onFilterChanged,
	onSearchTextPreUpdate = onSearchTextPreUpdate,
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

	-- contentsMenu:register("destroy", clearFilterBeforeTrigger)
	-- contentsMenu:findChild(GUI_ID_MenuContents_takeallbutton):register("mouseClick", clearFilterBeforeTrigger)
	-- contentsMenu:findChild(GUI_ID_MenuContents_removebutton):register("mouseClick", clearFilterBeforeTrigger)
	-- contentsMenu:findChild(GUI_ID_MenuContents_closebutton):register("mouseClick", clearFilterBeforeTrigger)

	-- Create the filters.
	contentsFilters:createElements(filterBlock)

	-- Focus the filter search bar.
	contentsFilters:focusSearchBar()
end
event.register("uiActivated", onMenuContentsActivated, { filter = "MenuContents" } )
