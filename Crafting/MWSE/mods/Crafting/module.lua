local crafting = {}

local recipes = {}

local UIID_CraftingMenu
local UIID_CraftingMenu_Input
local UIID_CraftingMenu_List

local function parseStack(stack)
	-- Figure out the id/count from what we're given.
	local id, count
	if (type(stack) == "string") then
		id = stack
	elseif (type(stack) == "table") then
		id = stack.item
		count = stack.count
	else
		error("Invalid stack type of '%s'.", type(stack))
	end

	-- Ensure that we were actually able to get the id.
	if (id == nil) then
		error("Invalid stack id. Could not determine result id.")
	end

	-- Try to get the base object for the crafting.
	local item = tes3.getObject(id)
	if (item == nil) then
		error("Invalid stack. Could not resolve id: '%s'.", id)
	end

	-- Don't define a count of 1
	if (count == 1) then
		count = nil
	end

	return {item = item, count = count}
end

crafting.registerRecipe = function(params)
	-- Get the handler.
	local handler = params.handler
	if (type(handler) ~= "string") then
		error("Invalid recipe package. No handler defined.")
	end

	-- Create the handler if it doesn't exist.
	if (recipes[handler] == nil) then
		recipes[handler] = {}
	end

	-- The result can be a simple string, or a table with id/count. Figure it out.
	local resultStack = parseStack(params.result)

	-- Go through and resolve dependencies.
	local requires = {}
	for _, stack in pairs(params.requires) do
		local reqStack = parseStack(stack)
		reqStack.consume = stack.consume or true
		table.insert(requires, reqStack)
	end

	-- Start in on our package.
	local package = {handler = handler, result = resultStack, requires = requires}

	-- Hook up events.
	package.onShowList = params.onShowList
	package.onCraftSuccess = params.onCraftSuccess
	package.onCraftFailure = params.onCraftFailure
	package.onCraftAttempt = params.onCraftAttempt

	table.insert(recipes[handler], package)
end

local currentHandler = nil

local function showCraftingTooltip(e)
	local packageIndex = e.source:getPropertyInt("CraftingMenu:Index")
	local package = recipes[currentHandler][packageIndex]

	local tooltip = tes3ui.createTooltipMenu()

	local nameLabel = tooltip:createLabel({ text = package.result.item.name })
	nameLabel.color = tes3ui.getPalette("header_color")
	nameLabel.borderTop = 2

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoWidth = true
	tooltipBlock.autoHeight = true
	tooltipBlock.borderLeft = 4
	tooltipBlock.borderRight = 4
	tooltipBlock.borderTop = 6

	local skillLabel = tooltipBlock:createLabel({ text = "Skill: Armorer" })

	tooltipBlock:createLabel({ text = "Items:" })

	for _, stack in pairs(package.requires) do
		local requiredItemBlock = tooltipBlock:createBlock({})
		requiredItemBlock.flowDirection = "left_to_right"
		requiredItemBlock.autoWidth = true
		requiredItemBlock.autoHeight = true
		requiredItemBlock.borderBottom = 2

		local requiredIcon = requiredItemBlock:createImage({ path = string.format("icons/%s", stack.item.icon) })
		requiredIcon.borderLeft = 6

		local itemCount = mwscript.getItemCount({ reference = tes3.player, item = stack.item })
		local requiredLabel = requiredItemBlock:createLabel({ text = string.format("%s (%d of %d)", stack.item.name, itemCount, stack.count) })
		requiredLabel.absolutePosAlignY = 0.5

		if (itemCount < (stack.count or 1)) then
			requiredLabel.color = tes3ui.getPalette("disabled_color")
		end
	end
end

local function onClickCraftingRow(e)
	local packageIndex = e.source:getPropertyInt("CraftingMenu:Index")
	local package = recipes[currentHandler][packageIndex]

	tes3.messageBox("Crafting: %s", package.result.item.name)

	crafting.closeCraftingMenu()
end

crafting.showCraftingMenu = function(params)
	local handler = params.handler

	-- Do nothing if the window is already open.
	if (tes3ui.findMenu(UIID_CraftingMenu) ~= nil) then
		return
	end

	crafting.filterOnlyCraftable = params.showOnlyCraftable or false
	crafting.filterName = params.filter

	currentHandler = handler

	-- Create menu.
	local menu = tes3ui.createMenu({id = UIID_CraftingMenu, dragFrame = true})
	menu.text = "Crafting"
	menu.width = 400
	menu.height = 700
	menu.minWidth = 400
	menu.minHeight = 500
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2

	-- Create crafting list.
	local list = menu:createVerticalScrollPane({ id = UIID_CraftingMenu_List })

	-- Go through recipes for this category and create a block for each one.
	for index, package in pairs(recipes[handler]) do
		local mainBlock = list:createBlock({})
		mainBlock.flowDirection = "left_to_right"
		mainBlock.widthProportional = 1.0
		mainBlock.autoHeight = true
		mainBlock.borderTop = 3
		mainBlock.borderBottom = 3
		mainBlock:setPropertyInt("CraftingMenu:Index", index)
		mainBlock:register("mouseClick", onClickCraftingRow)
		mainBlock:register("help", showCraftingTooltip)

		local result = package.result
		local item = result.item

		local image = mainBlock:createImage({ path = string.format("icons/%s", item.icon) })
		image.consumeMouseEvents = false

		local label = mainBlock:createLabel({ text = item.name })
		label.absolutePosAlignY = 0.5
		label.borderLeft = 6
		label.consumeMouseEvents = false
		
		local meetsRequirements = true
		for _, stack in pairs(package.requires) do
			local itemCount = mwscript.getItemCount({ reference = tes3.player, item = stack.item })
			if (itemCount < (stack.count or 1)) then
				meetsRequirements = false
				break
			end
		end

		mainBlock:setPropertyBool("CraftingMenu:MeetsRequirements", meetsRequirements)
		if (not meetsRequirements) then
			label.color = tes3ui.getPalette("disabled_color")
		end
	end

	local bottomBlock = menu:createBlock({})
	bottomBlock.flowDirection = "left_to_right"
	bottomBlock.widthProportional = 1.0
	bottomBlock.height = 32
	bottomBlock.borderTop = 3

	local filterLabel = bottomBlock:createLabel({ text = "Filter:" })
	filterLabel.absolutePosAlignY = 0.5
	filterLabel.borderRight = 2
	
	local filterInputBorder = bottomBlock:createThinBorder{}
	filterInputBorder.width = 175
	filterInputBorder.height = 24
	filterInputBorder.childAlignX = 0.5
	filterInputBorder.childAlignY = 0.5
	filterInputBorder.absolutePosAlignY = 0.5

	local filterInput = filterInputBorder:createTextInput({ id = UIID_CraftingMenu_Input })
	filterInput.borderLeft = 5
	filterInput.borderRight = 5
	filterInput.borderTop = 0
	filterInput.borderBottom = 0
	filterInput.borderAllSides = 0
	filterInput.widget.lengthLimit = 31
	filterInput:register("keyEnter", function()
		local text = filterInput.text
		if (text == "") then
			crafting.filterName = nil
		else
			crafting.filterName = filterInput.text
		end
		crafting.filterCraftingMenu()
	end)

	local toggleCraftableButton = bottomBlock:createButton({ text = "All" })
	toggleCraftableButton.absolutePosAlignX = 1.0
	toggleCraftableButton.absolutePosAlignY = 0.5
	toggleCraftableButton.borderRight = 65
	toggleCraftableButton:register("mouseClick", function()
		crafting.filterOnlyCraftable = not crafting.filterOnlyCraftable
		if (crafting.filterOnlyCraftable) then
			toggleCraftableButton.text = "Craftable"
		else
			toggleCraftableButton.text = "All"
		end
		crafting.filterCraftingMenu()
	end)

	local closeButton = bottomBlock:createButton({ text = "Close" })
	closeButton.absolutePosAlignX = 1.0
	closeButton.absolutePosAlignY = 0.5
	closeButton:register("mouseClick", crafting.closeCraftingMenu)

	crafting.filterCraftingMenu()

	menu:updateLayout()
	tes3ui.enterMenuMode(UIID_CraftingMenu)
	tes3ui.acquireTextInput(filterInput)
end

crafting.closeCraftingMenu = function()
	local menu = tes3ui.findMenu(UIID_CraftingMenu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

crafting.filterOnlyCraftable = false
crafting.filterName = nil

crafting.filterCraftingMenu = function()
	local craftingMenu = tes3ui.findMenu(UIID_CraftingMenu)
	if (craftingMenu == nil) then
		return 
	end

	local filterCraftable = crafting.filterOnlyCraftable
	local filterName = crafting.filterName and string.lower(crafting.filterName)

	local craftingMenuList = craftingMenu:findChild(UIID_CraftingMenu_List):findChild(tes3ui.registerID("PartScrollPane_pane"))
	for i = 1, #craftingMenuList.children do
		local block = craftingMenuList.children[i]

		if (filterCraftable and not block:getPropertyBool("CraftingMenu:MeetsRequirements")) then
			block.visible = false
		elseif (filterName) then
			local packageIndex = block:getPropertyInt("CraftingMenu:Index")
			local package = recipes[currentHandler][packageIndex]
			if (string.find(string.lower(package.result.item.name), filterName)) then
				block.visible = true
			else
				block.visible = false
			end
		else
			block.visible = true
		end
	end
end

crafting.preInitialized = function()
	-- Register any IDs we care about.
	UIID_CraftingMenu = tes3ui.registerID("CraftingMenu")
	UIID_CraftingMenu_Input = tes3ui.registerID("CraftingMenu::Input")
	UIID_CraftingMenu_List = tes3ui.registerID("CraftingMenu::List")
end

local function recipeSorter(a, b)
	return (a.result.item.name < b.result.item.name)
end

crafting.postInitialized = function()
	-- Sort each recipe list by name.
	for key, list in pairs(recipes) do
		table.sort(list, recipeSorter)
	end
end

return crafting
