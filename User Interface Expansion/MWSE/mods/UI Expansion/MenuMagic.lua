
local GUI_ID_MagicMenu_spell_costs = tes3ui.registerID("MagicMenu_spell_costs")
local GUI_ID_MagicMenu_spell_names = tes3ui.registerID("MagicMenu_spell_names")
local GUI_ID_MagicMenu_spell_percents = tes3ui.registerID("MagicMenu_spell_percents")
local GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")
local GUI_ID_MenuMagic = tes3ui.registerID("MenuMagic")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local GUI_ID_UIEXP_MagicMenu_SchoolFilters = tes3ui.registerID("UIEXP_MagicMenu_SchoolFilters")

local GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")

local common = require("UI Expansion.common")

InputController = tes3.worldController.inputController

----------------------------------------------------------------------------------------------------
-- Spell List: Filtering and Searching
----------------------------------------------------------------------------------------------------

local spellsListSearchText = nil
local spellsListSchoolWhitelist = {}
for name, id in pairs(tes3.magicSchool) do
	spellsListSchoolWhitelist[id] = true
end

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

	if (common.config.showHelpText) then
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
	if (not e.newlyCreated) then
		return
	end

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
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" } )

local function onEnterMenuMode(e)
    -- Filter criteria.
    spellsListSearchText = nil
    spellsListSchoolWhitelist = {}
    for name, id in pairs(tes3.magicSchool) do
        spellsListSchoolWhitelist[id] = true
    end

    -- Reset filter text.
    local menu = tes3ui.findMenu(GUI_ID_MenuMagic)
    local input = menu:findChild(tes3ui.registerID("UIEXP:MagicMenu:SearchInput"))
    input.text = "Search by name..."
    input.color = GUI_Palette_Disabled

    -- Reset GUI elements.
    local filtersBlock = menu:findChild(GUI_ID_UIEXP_MagicMenu_SchoolFilters)
    local filtersChildren = filtersBlock.children
    for _, element in pairs(filtersChildren) do
        element.alpha = 1.0
        element:updateLayout()
    end
    searchSpellsList()
end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })
