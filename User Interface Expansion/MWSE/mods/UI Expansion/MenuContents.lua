
local GUI_ID_CursorIcon = tes3ui.registerID("CursorIcon")
local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")
local GUI_ID_MenuContents_bucket = tes3ui.registerID("MenuContents_bucket")
local GUI_ID_MenuContents_takeallbutton = tes3ui.registerID("MenuContents_takeallbutton")

local common = require("UI Expansion.common")

local inputController = tes3.worldController.inputController

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
			takeAllButton.text = common.dictionary.takeFiltered
		else
			takeAllButton.text = common.dictionary.takeAll
		end
	end
	tes3ui.updateContentsMenuTiles()
end

local contentsFilters = common.createFilterInterface({
	createSearchBar = true,
	createIcons = true,
	createButtons = true,
	useIcons = not common.config.useInventoryTextButtons,
	useSearch = common.config.useSearch,
	onFilterChanged = onFilterChanged,
	onSearchTextPreUpdate = onSearchTextPreUpdate,
})
common.contentsFilter = contentsFilters

common.createStandardInventoryFilters(contentsFilters)

local function onFilterContentsMenu(e)
	e.text = e.item.name
	e.filter = contentsFilters:triggerFilter(e)
end
event.register("filterContentsMenu", onFilterContentsMenu)

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

	-- Create the filters.
	contentsFilters:createElements(filterBlock)

	-- Focus the filter search bar.
	contentsFilters:focusSearchBar()
end
event.register("uiActivated", onMenuContentsActivated, { filter = "MenuContents" } )

local function onContentTileClicked(e)
	-- Fire off an event when the tile is clicked for other modules to hook into.
	local tileData = e.source:getPropertyObject("MenuContents_Thing", "tes3inventoryTile")
	local eventData = {
		element = tileData.element,
		tile = tileData,
		item = tileData.item,
		itemData = tileData.itemData,
		count = tileData.count,
	}
	local response = event.trigger("UIEX:ContentsTileClicked", eventData, { filter = eventData.item })
	if (response.block) then
		return
	end

	-- Perform any normal logic.
	e.source:forwardEvent(e)
end

-- Claim mouse click events on item tiles.
local function onContentTileUpdated(e)
	e.element:register("mouseClick", onContentTileClicked)
end
event.register("itemTileUpdated", onContentTileUpdated, { filter = "MenuContents" })

-- Enable alt-clicking inventory items to transfer it to the contents menu.
local function onInventoryTileClicked(e)
	local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
	if (contentsMenu == nil) then
		return
	end

	-- If the player is holding the alt key, transfer the item directly.
	local isAltDown = inputController:isKeyDown(tes3.scanCode.lAlt)
	local isShiftDown = inputController:isKeyDown(tes3.scanCode.lShift)
	local transferByDefault = common.config.transferItemsByDefault
	if ((transferByDefault and not isAltDown and isShiftDown) or (not transferByDefault and isAltDown)) then
		local cursorIcon = tes3ui.findHelpLayerMenu(GUI_ID_CursorIcon)
		if (cursorIcon) then
			return
		end

		-- Prevent transfering equipped items.
		if (e.tile.isEquipped or e.tile.isBoundItem) then
			return
		end

		-- Holding control only transfers one item.
		local count = e.count
		if (inputController:isKeyDown(tes3.scanCode.lCtrl)) then
			count = 1
		end

		-- Transfer over the item(s).
		local containerRef = contentsMenu:getPropertyObject("MenuContents_ObjectRefr")
		tes3.transferItem({
			from = tes3.player,
			to = containerRef,
			item = e.item,
			itemData = e.itemData,
			count = count,
		})

		-- Trigger a crime if applicable.
		local owner = tes3.getOwner(containerRef)
		if (owner) then
			if (owner.playerJoined) then
				if (containerRef.attachments["variables"].requirement <= owner.playerRank) then
					return false
				end
			end
			tes3.triggerCrime({ type = 5, victim = owner, value = e.item.value * count })
		end

		return false
	end
end
event.register("UIEX:InventoryTileClicked", onInventoryTileClicked)

-- Enable alt-clicking contents items to transfer it to the inventory menu.
local function onContentsTileClicked(e)
	-- If the player is holding the alt key, transfer the item directly.
	local isAltDown = inputController:isKeyDown(tes3.scanCode.lAlt)
	local isShiftDown = inputController:isKeyDown(tes3.scanCode.lShift)
	local transferByDefault = common.config.transferItemsByDefault
	if ((transferByDefault and not isAltDown and not isShiftDown) or (not transferByDefault and isAltDown)) then
		local cursorIcon = tes3ui.findHelpLayerMenu(GUI_ID_CursorIcon)
		if (cursorIcon) then
			return
		end

		-- Prevent transfering equipped items.
		if (e.tile.isEquipped or e.tile.isBoundItem) then
			return
		end

		-- Holding control only transfers one item.
		local count = e.count
		if (inputController:isKeyDown(tes3.scanCode.lCtrl)) then
			count = 1
		end

		-- Transfer over the item(s).
		local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
		local containerRef = contentsMenu:getPropertyObject("MenuContents_ObjectRefr")
		tes3.transferItem({
			from = containerRef,
			to = tes3.player,
			item = e.item,
			itemData = e.itemData,
			count = count,
		})

		-- Trigger a crime if applicable.
		local owner = tes3.getOwner(containerRef)
		if (owner) then
			if (owner.playerJoined) then
				if (containerRef.attachments["variables"].requirement <= owner.playerRank) then
					return false
				end
			end
			tes3.triggerCrime({ type = 5, victim = owner, value = e.item.value * count })
		end

		return false
	end
end
event.register("UIEX:ContentsTileClicked", onContentsTileClicked)
