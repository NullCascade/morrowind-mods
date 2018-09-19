
local GUI_ID_HelpMenu
local GUI_ID_MagicMenu_spell_costs
local GUI_ID_MagicMenu_spell_names
local GUI_ID_MagicMenu_spell_percents
local GUI_ID_MagicMenu_spells_list
local GUI_ID_MenuInventory
local GUI_ID_MenuInventory_button_layout
local GUI_ID_MenuMagic
local GUI_ID_MenuStat_scroll_pane
local GUI_ID_PartScrollPane_pane

local GUI_ID_UIEXP_InventoryMenu_Filters
local GUI_ID_UIEXP_MagicMenu_SchoolFilters

local GUI_Palette_Normal
local GUI_Palette_Disabled
local GUI_Palette_Positive
local GUI_Palette_Negative

local InputController

local common = require("UI Expansion.common")

-- Configuration table.
local defaultConfig = {
	showHelpText = true,
}
local config = table.copy(defaultConfig)

-- Loads the configuration file for use.
local function loadConfig()
	-- Clear any current config values.
	config = {}

	-- First, load the defaults.
	table.copy(defaultConfig, config)

	-- Then load any other values from the config file.
	local configJson = mwse.loadConfig("UI Expansion")
	if (configJson ~= nil) then
		table.copy(configJson, config)
	end

	mwse.log("[UI Expansion] Loaded configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
loadConfig()

----------------------------------------------------------------------------------------------------
-- Inventory: Searching, sorting, and filtering.
----------------------------------------------------------------------------------------------------

local inventorySearchText = nil

local inventoryFilter = {
	["all"] = 0,
	["weapon"] = 1,
	["apparel"] = 2,
	["consumable"] = 3,
	["ingredient"] = 4,
	["tools"] = 5,
	["other"] = 6,
}

local inventoryActiveFilters = { [inventoryFilter.all] = true }

local inventoryFilterCallbacks = {}

function inventoryFilterCallbacks.all(e)
	return true
end

function inventoryFilterCallbacks.weapon(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.weapon or objectType == tes3.objectType.ammunition)
end

function inventoryFilterCallbacks.apparel(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.armor or objectType == tes3.objectType.clothing)
end

function inventoryFilterCallbacks.consumable(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.alchemy)
end

function inventoryFilterCallbacks.ingredient(e)
	local objectType = e.item.objectType
	return (objectType == tes3.objectType.ingredient)
end

function inventoryFilterCallbacks.tools(e)
	local objectType = e.item.objectType
	return (
		objectType == tes3.objectType.apparatus or 
		objectType == tes3.objectType.probe or 
		objectType == tes3.objectType.lockpick or 
		objectType == tes3.objectType.repairItem
	)
end

function inventoryFilterCallbacks.other(e)
	local objectType = e.item.objectType
	return (
		objectType == tes3.objectType.book or
		objectType == tes3.objectType.light or
		objectType == tes3.objectType.miscItem
	)
end

local function updateInventoryFilterIcons()
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuInventory)
	local filtersBlock = magicMenu:findChild(GUI_ID_UIEXP_InventoryMenu_Filters)
	local filtersChildren = filtersBlock.children
	local doAll = inventoryActiveFilters[inventoryFilter.all]
	for _, element in pairs(filtersChildren) do
		if (doAll) then
			element.alpha = 1.0
		else
			local id = element:getPropertyInt("UIEXP:Category")
			if (inventoryActiveFilters[id]) then
				element.alpha = 1.0
			else
				element.alpha = 0.5
			end
		end
		element:updateLayout()
	end
end

local function onInventoryFilterClick(e)
	local icon = e.source
	local id = icon:getPropertyInt("UIEXP:Category")
	local key = table.find(inventoryFilter, id)

	-- If this is the only filter active, reset to show all.
	local activeFilterCount = 0
	local activeFilter = nil
	for key, id in pairs(inventoryFilter) do
		if (inventoryActiveFilters[id]) then
			activeFilter = id
			activeFilterCount = activeFilterCount + 1
		end
	end
	if (activeFilterCount == 1 and activeFilter == id) then
		inventoryActiveFilters = { [inventoryFilter.all] = true }
		updateInventoryFilterIcons()
		tes3ui.updateInventoryTiles()
		return
	end

	-- If shift is pressed, toggle the element.
	if (InputController:isKeyDown(42)) then
		inventoryActiveFilters[id] = not inventoryActiveFilters[id]
		if (#inventoryActiveFilters >= #inventoryFilter - 1) then
			inventoryActiveFilters = { [inventoryFilter.all] = true }
		end
	else
		inventoryActiveFilters = { [id] = true }
		inventoryActiveFilters[inventoryFilter.all] = nil
	end

	updateInventoryFilterIcons()
	tes3ui.updateInventoryTiles()
end

local inventoryTooltipCallbacks = {}

function inventoryTooltipCallbacks.weapon(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to weapons" })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Ammunition" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Weapons" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.apparel(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to armor and clothing" })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Armor" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Clothing" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.consumable(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to consumables" })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Potions" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Scrolls" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- On-use enchantments" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.ingredient(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to ingredients" })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Ingredients" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.tools(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to tools and soulgems" })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Apparatus" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Lockpicks" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Probes" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Repair Tools" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Soulgems" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

function inventoryTooltipCallbacks.other(e)
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true

	tooltipBlock:createLabel({ text = "Filter to other items" })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter to:" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "- Books" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Lights" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "- Misc. Items" })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 2
		helpText.borderLeft = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

local function onInventoryFilterTooltip(e)
	local id = e.source:getPropertyInt("UIEXP:Category")
	local key = table.find(inventoryFilter, id)
	inventoryTooltipCallbacks[key](e)
end

local function filterInventory(e)
	-- Search by name.
	if (inventorySearchText and not string.find(string.lower(e.item.name), inventorySearchText)) then
		e.filter = false
		return
	end

	-- Otherwise go through active filters.
	for key, id in pairs(inventoryFilter) do
		if (not e.filter and inventoryActiveFilters[id]) then
			if (inventoryFilterCallbacks[key](e)) then
				e.filter = true
				return
			end
		end
	end

	e.filter = false
	return
end
event.register("filterInventory", filterInventory )

local function OnMenuInventoryActivated(e)
	local buttonBlock = e.element:findChild(GUI_ID_MenuInventory_button_layout)

	-- Start off by nuking our slate clean.
	buttonBlock:destroyChildren()

	-- Create search bar.
	common.createSearchBar({
		parent = buttonBlock,
		id = "UIEXP:InventoryMenu:SearchInput",
		placeholderText = "Search by name...",
		onUpdate = function(e)
			inventorySearchText = e.source.text
			if (inventorySearchText == "") then
				inventorySearchText = nil
			end
			tes3ui.updateInventoryTiles()
		end
	})

	-- Create icons for filtering.
	do
		local border = buttonBlock:createThinBorder({ id = GUI_ID_UIEXP_InventoryMenu_Filters })
		border.autoWidth = true
		border.autoHeight = true
		border.borderLeft = 4
		border.paddingTop = 2
		border.paddingBottom = 3
		border.paddingLeft = 2
		border.paddingRight = 3

		local function createFilterButton(e)
			local button = border:createImage({ path = e.icon })
			button.imageScaleX = 0.6
			button.imageScaleY = 0.6
			button.borderLeft = 2
			button:setPropertyInt("UIEXP:Category", inventoryFilter[e.key])
			button:register("mouseClick", onInventoryFilterClick)
			button:register("help", onInventoryFilterTooltip)
			return button
		end
		createFilterButton({ key = "weapon", icon = "icons/ui_exp/inventory_weapons.tga" }).borderLeft = 0
		createFilterButton({ key = "apparel", icon = "icons/ui_exp/inventory_apparel.tga" })
		createFilterButton({ key = "consumable", icon = "icons/ui_exp/inventory_consumables.tga" })
		createFilterButton({ key = "ingredient", icon = "icons/ui_exp/inventory_ingredients.tga" })
		createFilterButton({ key = "tools", icon = "icons/ui_exp/inventory_tools.tga" })
		createFilterButton({ key = "other", icon = "icons/ui_exp/inventory_other.tga" })
	end
end
event.register("uiActivated", OnMenuInventoryActivated, { filter = "MenuInventory" } )


----------------------------------------------------------------------------------------------------
-- Stats Menu: Display active modifiers.
----------------------------------------------------------------------------------------------------

local attributeModifyingEffects = { tes3.effect.drainAttribute, tes3.effect.damageAttribute, tes3.effect.fortifyAttribute }
local skillModifyingEffects = { tes3.effect.drainSkill, tes3.effect.damageSkill, tes3.effect.fortifySkill }

local function OnMenuStatTooltip(e, effectFilter, idProperty, fortifyEffect)
	-- Allow the tooltip to be made per usual.
	e.source:forwardEvent(e)

	-- Get the associated attribute.
	local attribute = e.source:getPropertyInt(idProperty)

	-- Create a new tooltip block.
	local tooltip = tes3ui.findHelpLayerMenu(GUI_ID_HelpMenu)
	local adjustmentsBlock = tooltip:createBlock({})
	adjustmentsBlock:createLabel({ text = "Modifiers:" })
	adjustmentsBlock.flowDirection = "top_to_bottom"
	adjustmentsBlock.autoHeight = true
	adjustmentsBlock.autoWidth = true
	adjustmentsBlock.widthProportional = 1.0
	adjustmentsBlock.borderLeft = 6
	adjustmentsBlock.borderRight = 6
	adjustmentsBlock.borderBottom = 6

	local magicEffects = tes3.dataHandler.nonDynamicData.magicEffects

	local modifierCount = 0
	local activeEffect = tes3.mobilePlayer.activeMagicEffects
	for i = 1, tes3.mobilePlayer.activeMagicEffectCount do
		activeEffect = activeEffect.next

		if (activeEffect.attributeId == attribute and table.find(effectFilter, activeEffect.effectId)) then
			local block = adjustmentsBlock:createBlock({})
			block.flowDirection = "left_to_right"
			block.widthProportional = 1.0
			block.autoWidth = true
			block.autoHeight = true
			block.borderLeft = 10
			block.borderRight = 10
			block.borderTop = 4
			
			local effect = magicEffects[activeEffect.effectId + 1]
	
			local icon = block:createImage({ path = string.format("icons/%s", effect.icon) })
			icon.borderRight = 6
	
			local sourceLabel = block:createLabel({ text = string.format("%s:", activeEffect.instance.source.name) })
			if (activeEffect.effectId == fortifyEffect) then
				local magnitudeLabel = block:createLabel({ text = string.format("+%d", activeEffect.magnitudeMin) })
				magnitudeLabel.color = GUI_Palette_Positive
				magnitudeLabel.borderLeft = 2
				magnitudeLabel.absolutePosAlignX = 1.0
			else
				local magnitudeLabel = block:createLabel({ text = string.format("-%d", activeEffect.magnitudeMin) })
				magnitudeLabel.color = GUI_Palette_Negative
				magnitudeLabel.borderLeft = 2
				magnitudeLabel.absolutePosAlignX = 1.0
			end

			modifierCount = modifierCount + 1
		end
	end

	if ( modifierCount < 1 ) then
		adjustmentsBlock.visible = false
	end
end

local function onMenuStatAttributeTooltip(e)
	OnMenuStatTooltip(e, attributeModifyingEffects, "MenuStat_attribute_strength", tes3.effect.fortifyAttribute)
end

local function onMenuStatSkillTooltip(e)
	OnMenuStatTooltip(e, skillModifyingEffects, "MenuStat_message", tes3.effect.fortifySkill)
end

local function onMenuStatActivated(e)
	local idParts = { "agility", "endurance", "intellegence", "luck", "personality", "speed", "strength", "willpower" }
	for _, idPart in pairs(idParts) do
		local MenuStat_attribute_layout = e.element:findChild(tes3ui.registerID(string.format("MenuStat_attribute_layout_%s", idPart)))
		MenuStat_attribute_layout:register("help", onMenuStatAttributeTooltip)

		-- Prevent children from using their own events.
		local children = MenuStat_attribute_layout.children
		for _, child in pairs(children) do
			child.consumeMouseEvents = false
		end
	end
end
event.register("uiActivated", onMenuStatActivated, { filter = "MenuStat" } )

local function onStatsMenuRefreshed(e)
	local idFilters = { tes3ui.registerID("MenuStat_misc_layout"), tes3ui.registerID("MenuStat_minor_layout"), tes3ui.registerID("MenuStat_major_layout") }
	local scrollPaneChildren = e.element:findChild(GUI_ID_MenuStat_scroll_pane):findChild(GUI_ID_PartScrollPane_pane).children
	for _, element in pairs(scrollPaneChildren) do
		if (table.find(idFilters, element.id)) then
			element:register("help", onMenuStatSkillTooltip)

			local children = element.children
			for _, child in pairs(children) do
				child.consumeMouseEvents = false
			end
		end
	end
end
event.register("uiRefreshed", onStatsMenuRefreshed, { filter = "MenuStat_scroll_pane" })


----------------------------------------------------------------------------------------------------
-- Spell List: Filtering and Searching
----------------------------------------------------------------------------------------------------

local spellsListSearchText = nil
local spellsListSchoolWhitelist = {}

local function spellMatchesFilter(spell)
	-- Filter by name.
	if (spellsListSearchText and not string.find(string.lower(spell.name), spellsListSearchText)) then
		return false
	end

	-- Filter by effects.
	for i = 1, #spell.effects do
		if (spellsListSchoolWhitelist[spell.effects[i].object.school]) then
			return true
		end
	end

	return false
end

local function searchSpellsList()
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
	local namesList = magicMenu:findChild(GUI_ID_MagicMenu_spell_names)
	local costsList = magicMenu:findChild(GUI_ID_MagicMenu_spell_costs)
	local percentsList = magicMenu:findChild(GUI_ID_MagicMenu_spell_percents)

	-- Get a list of all children for future manipulation.
	-- These tables are created newly each time .children is accessed.
	local namesChildren = namesList.children
	local costsChildren = costsList.children
	local percentsChildren = percentsList.children

	-- 
	for index = 1, #namesChildren do
		local element = namesChildren[index]

		local filter = spellMatchesFilter(element:getPropertyObject("MagicMenu_Spell"))
		if (filter ~= element.visible) then
			element.visible = filter
			costsChildren[index].visible = filter
			percentsChildren[index].visible = filter
		end
	end
end

local function toggleSchoolBlacklistFilter(e)
	local icon = e.source
	local school = icon:getPropertyInt("UIEXP:School")

	if (spellsListSchoolWhitelist[school]) then
		icon.alpha = 0.5
		spellsListSchoolWhitelist[school] = false
	else
		icon.alpha = 1.0
		spellsListSchoolWhitelist[school] = true
	end
	icon:updateLayout()

	searchSpellsList()
end

local function setSchoolBlacklistFilter(e)
	local icon = e.source
	local school = icon:getPropertyInt("UIEXP:School")
	
	-- If this is the only element activated, show all schools.
	local shownCount = 0
	local shownSchool = nil
	for school, state in pairs(spellsListSchoolWhitelist) do
		if (state) then
			shownSchool = school
			shownCount = shownCount + 1
		end
	end
	if (shownCount == 1 and shownSchool == school) then
		for school, state in pairs(spellsListSchoolWhitelist) do
			spellsListSchoolWhitelist[school] = true
		end
		
		local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
		local filtersBlock = magicMenu:findChild(GUI_ID_UIEXP_MagicMenu_SchoolFilters)
		local filtersChildren = filtersBlock.children
		for _, element in pairs(filtersChildren) do
			element.alpha = 1.0
			element:updateLayout()
		end

		searchSpellsList()
		return
	end

	-- If shift is pressed, toggle the element.
	if (InputController:isKeyDown(42)) then
		toggleSchoolBlacklistFilter(e)
		return 
	end

	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)

	local filtersBlock = magicMenu:findChild(GUI_ID_UIEXP_MagicMenu_SchoolFilters)
	local filtersChildren = filtersBlock.children
	for _, element in pairs(filtersChildren) do
		element.alpha = 0.5
		element:updateLayout()
	end

	icon.alpha = 1.0
	icon:updateLayout()

	for name, id in pairs(tes3.magicSchool) do
		spellsListSchoolWhitelist[id] = false
	end
	
	spellsListSchoolWhitelist[school] = true

	searchSpellsList()
end

local function onSchoolFilterTooltip(e)
	local icon = e.source
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true
	
	local schoolId = icon:getPropertyInt("UIEXP:School")
	local skillId = tes3.magicSchoolSkill[schoolId]

	tooltipBlock:createLabel({ text = string.format("Filter by %s", tes3.getSkill(skillId).name) })

	if (config.showHelpText) then
		local helpText
		
		helpText = tooltipBlock:createLabel({ text = "Click to filter by school." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "Click again to remove filter." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "Shift+Click to add to/remove from filter." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6

		helpText = tooltipBlock:createLabel({ text = "Help text can be disabled in the Mod Config Menu." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end
end

local function onMenuMagicActivated(e)
	local spellsList = e.element:findChild(GUI_ID_MagicMenu_spells_list)
	local spellsListContents = spellsList:findChild(GUI_ID_PartScrollPane_pane)

	-- Make the parent block order from top to bottom.
	local spellsListParent = spellsList.parent
	spellsListParent.flowDirection = "top_to_bottom"

	-- Create the filter block where our search bar and filter icons will live.
	local filterBlock = spellsListParent:createBlock({ id = "UIEXP:MagicMenu:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4

	common.createSearchBar({
		parent = filterBlock,
		id = "UIEXP:MagicMenu:SearchInput",
		placeholderText = "Search by name...",
		onUpdate = function(e)
			spellsListSearchText = e.source.text
			if (spellsListSearchText == "") then
				spellsListSearchText = nil
			end
			searchSpellsList()
		end
	})
	
	-- Create magic school filter border.
	local schoolFilterBorder = filterBlock:createThinBorder({ id = GUI_ID_UIEXP_MagicMenu_SchoolFilters })
	schoolFilterBorder.autoWidth = true
	schoolFilterBorder.autoHeight = true
	schoolFilterBorder.borderLeft = 4
	schoolFilterBorder.paddingTop = 2
	schoolFilterBorder.paddingBottom = 3
	schoolFilterBorder.paddingLeft = 2
	schoolFilterBorder.paddingRight = 3

	-- Create the individual filter icons.
	do
		local schoolFilterAlteration = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_alteration.tga" })
		schoolFilterAlteration.imageScaleX = 0.6
		schoolFilterAlteration.imageScaleY = 0.6
		schoolFilterAlteration:setPropertyInt("UIEXP:School", tes3.magicSchool.alteration)
		schoolFilterAlteration:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterAlteration:register("help", onSchoolFilterTooltip)

		local schoolFilterConjuration = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_conjuration.tga" })
		schoolFilterConjuration.borderLeft = 2
		schoolFilterConjuration.imageScaleX = 0.6
		schoolFilterConjuration.imageScaleY = 0.6
		schoolFilterConjuration:setPropertyInt("UIEXP:School", tes3.magicSchool.conjuration)
		schoolFilterConjuration:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterConjuration:register("help", onSchoolFilterTooltip)
		
		local schoolFilterDestruction = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_destruction.tga" })
		schoolFilterDestruction.borderLeft = 2
		schoolFilterDestruction.imageScaleX = 0.6
		schoolFilterDestruction.imageScaleY = 0.6
		schoolFilterDestruction:setPropertyInt("UIEXP:School", tes3.magicSchool.destruction)
		schoolFilterDestruction:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterDestruction:register("help", onSchoolFilterTooltip)
		
		local schoolFilterIllusion = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_illusion.tga" })
		schoolFilterIllusion.borderLeft = 2
		schoolFilterIllusion.imageScaleX = 0.6
		schoolFilterIllusion.imageScaleY = 0.6
		schoolFilterIllusion:setPropertyInt("UIEXP:School", tes3.magicSchool.illusion)
		schoolFilterIllusion:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterIllusion:register("help", onSchoolFilterTooltip)
		
		local schoolFilterMysticism = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_mysticism.tga" })
		schoolFilterMysticism.borderLeft = 2
		schoolFilterMysticism.imageScaleX = 0.6
		schoolFilterMysticism.imageScaleY = 0.6
		schoolFilterMysticism:setPropertyInt("UIEXP:School", tes3.magicSchool.mysticism)
		schoolFilterMysticism:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterMysticism:register("help", onSchoolFilterTooltip)
		
		local schoolFilterRestoration = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_restoration.tga" })
		schoolFilterRestoration.borderLeft = 2
		schoolFilterRestoration.imageScaleX = 0.6
		schoolFilterRestoration.imageScaleY = 0.6
		schoolFilterRestoration:setPropertyInt("UIEXP:School", tes3.magicSchool.restoration)
		schoolFilterRestoration:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterRestoration:register("help", onSchoolFilterTooltip)
	end

	-- Move the filter options to the top of the block.
	spellsListParent:reorderChildren(0, -1, 1)

	-- Default to spell searching.
	-- tes3ui.acquireTextInput(searchInput)
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" } )


----------------------------------------------------------------------------------------------------
-- Initialization: Data collection, MCM, and UI ID registration.
----------------------------------------------------------------------------------------------------

local modConfig = require("UI Expansion.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("UI Expansion", modConfig)
end
event.register("modConfigReady", registerModConfig)

local function onInitialized(e)
	-- Pre-register extant GUI IDs.
	GUI_ID_HelpMenu = tes3ui.registerID("HelpMenu")
	GUI_ID_MagicMenu_spell_costs = tes3ui.registerID("MagicMenu_spell_costs")
	GUI_ID_MagicMenu_spell_names = tes3ui.registerID("MagicMenu_spell_names")
	GUI_ID_MagicMenu_spell_percents = tes3ui.registerID("MagicMenu_spell_percents")
	GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")
	GUI_ID_MenuInventory = tes3ui.registerID("MenuInventory")
	GUI_ID_MenuInventory_button_layout = tes3ui.registerID("MenuInventory_button_layout")
	GUI_ID_MenuMagic = tes3ui.registerID("MenuMagic")
	GUI_ID_MenuStat_scroll_pane = tes3ui.registerID("MenuStat_scroll_pane")
	GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

	-- Pre-register new GUI IDs.
	GUI_ID_UIEXP_InventoryMenu_Filters = tes3ui.registerID("UIEXP_InventoryMenu_Filters")
	GUI_ID_UIEXP_MagicMenu_SchoolFilters = tes3ui.registerID("UIEXP_MagicMenu_SchoolFilters")

	-- Pre-register pallets.
	GUI_Palette_Normal = tes3ui.getPalette("normal_color")
	GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")
	GUI_Palette_Positive = tes3ui.getPalette("positive_color")
	GUI_Palette_Negative = tes3ui.getPalette("negative_color")

	-- Fill the school filter whitelist.
	for name, id in pairs(tes3.magicSchool) do
		spellsListSchoolWhitelist[id] = true
	end

	-- Fill in short hand variables.
	InputController = tes3.worldController.inputController
end
event.register("initialized", onInitialized)
