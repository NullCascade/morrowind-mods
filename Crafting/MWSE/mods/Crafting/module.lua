local skillsModule = include("OtherSkills.skillModule")

local crafting = {}

local handlers = {}

local recipes = {}

local UIID_CraftingMenu
local UIID_CraftingMenu_Input
local UIID_CraftingMenu_List
local UIID_CraftingMenu_ListBlock_Label

local UI_Palette_Disabled
local UI_Palette_Header

crafting.loadConfig = function()
	crafting.config = mwse.loadConfig("Comprehensive Crafting")

	-- Handle defaults.
	crafting.config = crafting.config or {}
	crafting.config.debugMode = crafting.config.debugMode or false
	crafting.config.showOnlyCraftable = crafting.config.showOnlyCraftable or false
	crafting.config.fLevelingDifficultyScalarXP = crafting.config.fLevelingDifficultyScalarXP or 0.0
	crafting.config.fLevelingFlatXP = crafting.config.fLevelingFlatXP or 5.0
end

crafting.saveConfig = function()
	mwse.saveConfig("Comprehensive Crafting", crafting.config)
end

crafting.loadConfig()

local debugPrint = function() end
if (crafting.config.debugMode) then
	debugPrint = function(s, ...)
		mwse.log(string.format("[Comprehensive Crafting] %s", s:format(...)))
	end
end

local function parseStack(stack)
	-- Figure out the id/count from what we're given.
	local id, count
	if (type(stack) == "string") then
		id = stack
	elseif (type(stack) == "table") then
		id = stack.id
		count = stack.count
	else
		error(string.format("Invalid stack type of '%s'.", type(stack)))
	end

	-- Ensure that we were actually able to get the id.
	if (id == nil) then
		error("Invalid stack id. Could not determine result id.")
	end

	-- Try to get the base object for the crafting.
	local item = tes3.getObject(id)
	if (item == nil) then
		error(string.format("Invalid stack. Could not resolve id: '%s'.", id))
	end

	-- Don't define a count of 1
	if (count == 1) then
		count = nil
	end

	return { item = item, count = count }
end

local function getSkill(param)
	local skill
	if (type(param) == "number") then
		skill = tes3.getSkill(param)
		if (skill == nil) then
			error(string.format("Invalid skill id: %s", param))
		end
		return skill
	elseif (skillsModule and type(param) == "string") then
		skill = skillsModule.getSkill(param)
		if (skill == nil) then
			error(string.format("Invalid custom skill id: %s", param))
		end
		return skill
	end
	
	error(string.format("Could not determine type of skill '%s'. Broken skill definition, or Skills Module may not be installed.", param))
end

local function getSkillStatistic(param)
	if (type(param) == "number") then
		return tes3.mobilePlayer.skills[param + 1]
	elseif (skillsModule and type(param) == "string") then
		local skill = skillsModule.getSkill(param)
		if (skill == nil) then
			error(string.format("Invalid custom skill id: %s", param))
		end
		return skill
	end
	
	error(string.format("Could not determine type of skill '%s'. Broken skill definition, or Skills Module may not be installed.", param))
end

local function packageMeetsRequirements(package)
	-- Item requirements.
	for _, stack in pairs(package.itemReqs) do
		-- Get the item count, checking cache.
		local itemCount = crafting.getItemCount(stack.item)
		if (itemCount < (stack.count or 1)) then
			return false
		end
	end

	-- Skill requirements.
	if (package.skillReqs) then
		for _, req in pairs(package.skillReqs) do
			if (getSkillStatistic(req.skill).base < req.value) then
				return false
			end
		end
	end

	-- Data requirements.
	if (package.dataReqs) then
		for _, req in pairs(package.dataReqs) do
			local value = tes3.player.data[req.id]
			if (value < req.min or value > req.max) then
				return false
			end
		end
	end

	-- Global variable requirements.
	if (package.globalReqs) then
		for _, req in pairs(package.globalReqs) do
			local value = req.global.value
			if (value < req.min or value > req.max) then
				return false
			end
		end
	end

	-- Custom requirements.
	if (package.customReqs) then
		for _, req in pairs(package.customReqs) do
			if (not req.callback(package)) then
				return false
			end
		end
	end

	return true
end

crafting.registerHandler = function(params)
	local recipeList = {}

	if (handlers[params.id] ~= nil) then
		error(string.format("Handler with id '%s' is already registered.", params.id))
	end

	local handler = { id = params.id, recipes = recipeList }
	
	if (params.successSound) then
		handler.successSound = tes3.getSound(params.successSound)
	end
	if (params.failureSound) then
		handler.failureSound = tes3.getSound(params.failureSound)
	end


	handlers[handler.id] = handler
	recipes[handler.id] = recipeList
end

crafting.registerRecipe = function(params)
	-- The result can be a simple string, or a table with id/count. Figure it out.
	local resultStack = parseStack(params.result)

	-- Go through and resolve item dependencies.
	local itemReqs = {}
	for _, stack in pairs(params.itemReqs) do
		local reqStack = parseStack(stack)
		reqStack.consume = stack.consume or true
		table.insert(itemReqs, reqStack)
	end

	-- Go through skill requirements.
	local skillReqs
	if (params.skillReqs) then
		skillReqs = {}
		for _, req in pairs(params.skillReqs) do
			table.insert(skillReqs, { skill = req.id, value = req.value })
		end

		if (#skillReqs == 0) then
			skillReqs = nil
		end
	end

	-- Player data requirements.
	local dataReqs = params.dataReqs
	if (dataReqs and #dataReqs == 0) then
		dataReqs = nil
	end
	
	-- Resolve global requirements.
	local globalReqs
	if (params.globalReqs) then
		globalReqs = {}
		for _, req in pairs(params.globalReqs) do
			if (req.text) then
				local global = tes3.findGlobal(req.id)
				if (global) then
					table.insert(globalReqs, { global = global, min = req.min, max = req.max, text = req.text })
				else
					error(string.format("Invalid global id: %s", req.id))
				end
			else
				error(string.format("Invalid global variable requirement of '%s'. Must provide tooltip text.", req.id))
			end
		end

		if (#globalReqs == 0) then
			globalReqs = nil
		end
	end
	
	-- TODO: Need a tes3.getJournal or the like.
	-- Resolve journal requirements.
	-- local journalReqs = {}
	-- for _, req in pairs(params.journalReqs) do
	-- 	
	-- end

	-- Custom requirements.
	local customReqs = params.customReqs
	if (customReqs and #customReqs == 0) then
		customReqs = nil
	end

	-- Start in on our package.
	local package = { result = resultStack, description = params.description, skill = params.skill, itemReqs = itemReqs, skillReqs = skillReqs, dataReqs = dataReqs, globalReqs = globalReqs, journalReqs = journalReqs, customReqs = customReqs }

	-- Get the override sounds.
	if (params.successSound) then
		package.successSound = tes3.getSound(params.successSound)
	end
	if (params.failureSound) then
		package.failureSound = tes3.getSound(params.failureSound)
	end

	-- Hook up events and other properties.
	package.difficulty = params.difficulty
	package.onShowList = params.onShowList
	package.onCraftSuccess = params.onCraftSuccess
	package.onCraftFailure = params.onCraftFailure
	package.onCraftAttempt = params.onCraftAttempt

	-- Add the package to a handler, or all handlers if a table is provided.
	if (type(params.handler) == "string") then
		if (recipes[params.handler]) then
			table.insert(recipes[params.handler], package)
		else
			error("No handler found for package.")
		end
	elseif (type(params.handler) == "table") then
		for _, handler in pairs(params.handler) do
			if (recipes[handler]) then
				table.insert(recipes[handler], package)
			else
				mwse.log("Warning: Handler with key '%s' could not be found for package.", handler)
			end
		end
	end
	
	-- If we already initialized the list, we need to go and resort.
	if (crafting.wasInitialized) then
		crafting.sortRecipes()
	end
end

local currentHandler = nil

local function showCraftingTooltip(e)
	local packageIndex = e.source:getPropertyInt("CraftingMenu:Index")
	local package = recipes[currentHandler][packageIndex]

	local tooltip = tes3ui.createTooltipMenu()

	local nameText = package.result.item.name
	if ((package.result.count or 1) > 1) then
		nameText = string.format("%s (%d)", nameText, package.result.count)
	end

	local nameLabel = tooltip:createLabel({ text = nameText })
	nameLabel.color = UI_Palette_Header
	nameLabel.borderTop = 2

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoWidth = true
	tooltipBlock.autoHeight = true
	tooltipBlock.maxWidth = 400
	tooltipBlock.borderLeft = 4
	tooltipBlock.borderRight = 4
	tooltipBlock.borderTop = 6
	tooltipBlock.borderBottom = 2

	if (package.description) then
		local descriptionLabel = tooltipBlock:createLabel({ text = package.description })
		descriptionLabel.color = UI_Palette_Header
		descriptionLabel.wrapText = true
		descriptionLabel.borderBottom = 6
	end

	local governingSkill = getSkill(package.skill)
	local skillLabel = tooltipBlock:createLabel({ text = string.format("Skill: %s", governingSkill.name) })

	-- Item requirements.
	local itemReqLabel = tooltipBlock:createLabel({ text = "Components:" })
	itemReqLabel.borderTop = 6
	for _, stack in pairs(package.itemReqs) do
		local requirementBlock = tooltipBlock:createBlock({})
		requirementBlock.flowDirection = "left_to_right"
		requirementBlock.autoWidth = true
		requirementBlock.autoHeight = true

		local icon = requirementBlock:createImage({ path = string.format("icons/%s", stack.item.icon) })
		icon.borderLeft = 6

		local itemCount = crafting.getItemCount(stack.item)
		local label = requirementBlock:createLabel({ text = string.format("%s (%d of %d)", stack.item.name, itemCount, stack.count) })
		label.absolutePosAlignY = 0.5

		if (itemCount < (stack.count or 1)) then
			label.color = UI_Palette_Disabled
		end
	end

	local otherReqsBlock = tooltipBlock:createBlock({})
	otherReqsBlock.flowDirection = "top_to_bottom"
	otherReqsBlock.autoWidth = true
	otherReqsBlock.autoHeight = true
	local hasOtherReqs = false

	local otherReqsLabel = otherReqsBlock:createLabel({ text = "Requirements:" })
	otherReqsLabel.borderTop = 4

	-- Skill requirements.
	if (package.skillReqs) then
		for _, req in pairs(package.skillReqs) do
			local skill = getSkill(req.skill)
			local skillStat = getSkillStatistic(req.skill)

			local label = otherReqsBlock:createLabel({ text = string.format("- %s of %d or higher.", skill.name, req.value) })
			label.borderLeft = 12

			if (skillStat.base < req.value) then
				label.color = UI_Palette_Disabled
			end

			hasOtherReqs = true
		end
	end

	-- Data requirements.
	if (package.dataReqs) then
		for _, req in pairs(package.dataReqs) do
			local text = req.text
			if (text) then
				local label = otherReqsBlock:createLabel({ text = string.format("- %s", text) })
				label.borderLeft = 12

				local value = tes3.player.data[req.id]
				if (value < req.min or value > req.max) then
					label.color = UI_Palette_Disabled
				end

				hasOtherReqs = true
			end
		end
	end

	-- Global variable requirements.
	if (package.globalReqs) then
		for _, req in pairs(package.globalReqs) do
			local text = req.text
			if (text) then
				local label = otherReqsBlock:createLabel({ text = string.format("- %s", text) })
				label.borderLeft = 12

				local value = req.global.value
				if (value < req.min or value > req.max) then
					label.color = UI_Palette_Disabled
				end
				
				hasOtherReqs = true
			end
		end
	end

	-- Custom requirements.
	if (package.customReqs) then
		for _, req in pairs(package.customReqs) do
			local label = otherReqsBlock:createLabel({ text = string.format("- %s", req.text) })
			label.borderLeft = 12

			if (req.callback(package) == false) then
				label.color = UI_Palette_Disabled
			end
			
			hasOtherReqs = true
		end
	end

	if (not hasOtherReqs) then
		otherReqsBlock.visible = false
	end
end

local function onClickCraftingRow(e)
	local packageIndex = e.source:getPropertyInt("CraftingMenu:Index")
	local handler = handlers[currentHandler]
	local package = recipes[currentHandler][packageIndex]

	local attempt = {}

	debugPrint("Crafting: %s (%d)", package.result.item.id, package.result.count or 1)

	-- Do we meet the requirements?
	if (not packageMeetsRequirements(package)) then
		debugPrint("Does not meet requirements!")
		return
	end

	-- Determine the chance of crafting.
	local governingSkill = getSkill(package.skill)
	local attribute = governingSkill.attribute and tes3.mobilePlayer.attributes[governingSkill.attribute + 1].base or 0
	local skill = getSkillStatistic(package.skill).base
	local luck = tes3.mobilePlayer.luck.base
	local fatigue = tes3.mobilePlayer.fatigue
	attempt.chance = (attribute/10 + luck/10 + skill - (package.difficulty or 0)) * (fatigue.current / fatigue.base)

	-- Determine success.
	attempt.roll = math.random(1, 100)
	attempt.success = attempt.chance >= attempt.roll

	-- Fire off the event so that others can manipulate this.
	if (package.onCraftAttempt) then
		package.onCraftAttempt(package, attempt)
	end

	-- Was this blocked?
	if (attempt.block) then
		return
	end

	-- Train the associated skill.
	if (attempt.success) then
		local experience = (package.difficulty or 0) * crafting.config.fLevelingDifficultyScalarXP + crafting.config.fLevelingFlatXP
		if (type(package.skill) == "number") then
			tes3.mobilePlayer:exerciseSkill(package.skill, experience)
		elseif (skillsModule and type(package.skill) == "string") then
			skillsModule.incrementSkill(package.skill, { progress = experience })
		end
	else
		-- TODO: Failure-based experience option?
	end
	
	-- Add/remove the associated items.
	if (attempt.success) then
		crafting.itemCountsChanged = true
		debugPrint("crafting.itemCountsChanged = true")

		-- Add the item to the player's inventory.
		mwscript.addItem({ reference = tes3.player, item = package.result.item, count = package.result.count })
	
		-- Remove the required items.
		for _, req in pairs(package.itemReqs) do
			if (package.consume ~= false) then
				mwscript.removeItem({ reference = tes3.player, item = req.item, count = req.count })
			end
		end
	else
		-- TODO: Chance to remove required items on failure? Need some cost of failure.
	end
	
	-- Play the associated sound.
	local sound = attempt.success and (package.successSound or handler.successSound) or (package.failureSound or handler.failureSound)
	if (sound) then
		sound:play()
	end

	-- Invoke any success/failure callbacks.
	if (success and package.onCraftSuccess) then
		package.onCraftSuccess(package, attempt)
	elseif (not success and package.onCraftFailure) then
		package.onCraftFailure(package, attempt)
	end

	-- Update GUI.
	crafting.filterCraftingMenu()
end

crafting.showCraftingMenu = function(params)
	local handler = params.handler

	-- Do nothing if the window is already open.
	if (tes3ui.findMenu(UIID_CraftingMenu) ~= nil) then
		return
	end

	crafting.config.showOnlyCraftable = params.showOnlyCraftable or false
	crafting.filterName = params.filter
	crafting.itemCountsChanged = true

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
		mainBlock.borderAllSides = 3
		mainBlock:setPropertyInt("CraftingMenu:Index", index)
		mainBlock:register("mouseClick", onClickCraftingRow)
		mainBlock:register("help", showCraftingTooltip)

		local result = package.result
		local item = result.item

		local image = mainBlock:createImage({ path = string.format("icons/%s", item.icon) })
		image.consumeMouseEvents = false

		local labelText = item.name
		if ((result.count or 1) > 1) then
			labelText = string.format("%s (%d)", item.name, result.count)
		end

		local label = mainBlock:createLabel({ id = UIID_CraftingMenu_ListBlock_Label, text = labelText })
		label.absolutePosAlignY = 0.5
		label.borderLeft = 6
		label.consumeMouseEvents = false

		if (package.onShowList) then
			package.onShowList(package, mainBlock)
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
		crafting.config.showOnlyCraftable = not crafting.config.showOnlyCraftable
		if (crafting.config.showOnlyCraftable) then
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

crafting.itemCountsChanged = false

crafting.itemCountCache = {}

crafting.getItemCount = function(item)
	local itemCount = crafting.itemCountCache[item]
	if (itemCount == nil) then
		itemCount = mwscript.getItemCount({ reference = tes3.player, item = item })
		debugPrint("crafting.itemCountCache[%s] = %d", item, itemCount)
		crafting.itemCountCache[item] = itemCount
	end
	return itemCount
end

crafting.filterCraftingMenu = function()
	local craftingMenu = tes3ui.findMenu(UIID_CraftingMenu)
	if (craftingMenu == nil) then
		return 
	end

	debugPrint("Filtering list.")

	local filterCraftable = crafting.config.showOnlyCraftable
	local filterName = crafting.filterName and string.lower(crafting.filterName)

	if (crafting.itemCountsChanged) then
		crafting.itemCountCache = {}
		debugPrint("Cleared item count cache.")
	end

	local craftingMenuList = craftingMenu:findChild(UIID_CraftingMenu_List):findChild(tes3ui.registerID("PartScrollPane_pane"))
	for i = 1, #craftingMenuList.children do
		local block = craftingMenuList.children[i]
		local packageIndex = block:getPropertyInt("CraftingMenu:Index")
		local package = recipes[currentHandler][packageIndex]

		local meetsReqs = packageMeetsRequirements(package)

		local label = block:findChild(UIID_CraftingMenu_ListBlock_Label)
		if (not meetsReqs) then
			label.color = UI_Palette_Disabled
		end

		if (filterCraftable and not meetsReqs) then
			block.visible = false
		elseif (filterName and not string.find(string.lower(package.result.item.name), filterName)) then
			block.visible = false
		else
			block.visible = true
		end
	end

	crafting.itemCountsChanged = false
	craftingMenu:updateLayout()
end

local function recipeSorter(a, b)
	return (a.result.item.name < b.result.item.name)
end

crafting.sortRecipes = function()
	-- Sort each recipe list by name.
	for key, list in pairs(recipes) do
		table.sort(list, recipeSorter)
	end
end

crafting.wasInitialized = false

crafting.preInitialized = function()
	-- Register any IDs we care about.
	UIID_CraftingMenu = tes3ui.registerID("CraftingMenu")
	UIID_CraftingMenu_Input = tes3ui.registerID("CraftingMenu::Input")
	UIID_CraftingMenu_List = tes3ui.registerID("CraftingMenu::List")
	UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("CraftingMenu::ListBlockLabel")
	
	UI_Palette_Disabled = tes3ui.getPalette("disabled_color")
	UI_Palette_Header = tes3ui.getPalette("header_color")
end

crafting.postInitialized = function()
	crafting.sortRecipes()

	crafting.wasInitialized = true
end

return crafting
