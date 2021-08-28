local GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")
local GUI_ID_MenuMagic = tes3ui.registerID("MenuMagic")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Spell List: Filtering and Searching
----------------------------------------------------------------------------------------------------

--- @type tes3uiElement
local firstSearchResult = nil

--- Helper function to search element text.
--- @param titleElement tes3uiElement
--- @param listElement tes3uiElement
--- @param isSpellFilter boolean
--- @return boolean
local function searchSubList(titleElement, listElement, isSpellFilter)
	-- Gather a list of all the columns/rows so we don't have to keep creating tables later.
	local columnElements = {}
	for _, element in ipairs(listElement.children) do
		table.insert(columnElements, element.children)
	end

	-- Go through and compare each element in listElement to our filter.
	local matchCount = 0
	for i, nameElement in ipairs(columnElements[1]) do
		local filterObject = nameElement:getPropertyObject(isSpellFilter and "MagicMenu_Spell" or "MagicMenu_object")
		local filter = common.allFilters.magic:triggerFilter({
			text = filterObject.name,
			effects = (isSpellFilter and filterObject.effects or filterObject.enchantment.effects),
		})

		if (filter) then
			matchCount = matchCount + 1
		end

		-- If we don't have a first hit already, set it now.
		if (isSpellFilter and firstSearchResult == nil and filter) then
			firstSearchResult = nameElement
		end

		-- If the state changed, change the element visibility in all columns.
		if (filter ~= nameElement.visible) then
			for _, column in ipairs(columnElements) do
				column[i].visible = filter
			end
		end
	end

	-- Hide associated elements if there aren't any results.
	if (matchCount > 0) then
		titleElement.visible = true
		listElement.visible = true
		return true
	else
		titleElement.visible = false
		listElement.visible = false
		return false
	end
end

--- Performs a search on the spells list.
local function searchSpellsList()
	-- Clear first search result hit.
	firstSearchResult = nil

	-- Get magic menu.
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
	if (not magicMenu) then
		return
	end

	-- Get spells list.
	local spellsList = magicMenu:findChild(GUI_ID_MagicMenu_spells_list)
	if (not spellsList) then
		return
	end

	-- Filter all of our sub groups.
	local elements = spellsList.widget.contentPane.children
	local hasMatchingPowers = searchSubList(elements[1], elements[2], true)
	local hasMatchingSpells = searchSubList(elements[4], elements[5], true)
	local hasMatchingItems = searchSubList(elements[7], elements[8], false)

	-- Figure out dividers.
	elements[3].visible = (hasMatchingPowers and hasMatchingSpells)
	elements[6].visible = (hasMatchingSpells and hasMatchingItems or
	                      (not hasMatchingSpells and hasMatchingPowers and hasMatchingItems))

	if (common.allFilters.magic.searchText and common.config.selectSpellsOnSearch and firstSearchResult) then
		firstSearchResult:triggerEvent("mouseClick")
	end
end

local magicFilters = common.createFilterInterface({
	filterName = "magic",
	createSearchBar = true,
	createIcons = true,
	createButtons = false,
	useIcons = true,
	useSearch = common.config.useSearch,
	onFilterChanged = searchSpellsList,
})

--- Determines if an array of effects contains an effect with the given school.
--- @param effects tes3effect[]
--- @param school number
--- @return boolean
local function getEffectsContainsSchool(effects, school)
	for i = 1, #effects do
		local eff = effects[i]
		if eff then
			local magicEffect = eff.object
			if magicEffect and eff.object.school == school then
				return true
			end
		end
	end
	return false
end

magicFilters:addFilter({
	key = "alteration",
	callback = function(e)
		return getEffectsContainsSchool(e.effects, tes3.magicSchool.alteration)
	end,
	tooltip = {
		text = common.i18n("filter.alteration.text"),
		helpText = common.i18n("filter.alteration.helpText"),
	},
	icon = "icons/ui_exp/magic_alteration.tga",
})

magicFilters:addFilter({
	key = "conjuration",
	callback = function(e)
		return getEffectsContainsSchool(e.effects, tes3.magicSchool.conjuration)
	end,
	tooltip = {
		text = common.i18n("filter.conjuration.text"),
		helpText = common.i18n("filter.conjuration.helpText"),
	},
	icon = "icons/ui_exp/magic_conjuration.tga",
})

magicFilters:addFilter({
	key = "destruction",
	callback = function(e)
		return getEffectsContainsSchool(e.effects, tes3.magicSchool.destruction)
	end,
	tooltip = {
		text = common.i18n("filter.destruction.text"),
		helpText = common.i18n("filter.destruction.helpText"),
	},
	icon = "icons/ui_exp/magic_destruction.tga",
})

magicFilters:addFilter({
	key = "illusion",
	callback = function(e)
		return getEffectsContainsSchool(e.effects, tes3.magicSchool.illusion)
	end,
	tooltip = { text = common.i18n("filter.illusion.text"),
             helpText = common.i18n("filter.illusionHelpText") },
	icon = "icons/ui_exp/magic_illusion.tga",
})

magicFilters:addFilter({
	key = "mysticism",
	callback = function(e)
		return getEffectsContainsSchool(e.effects, tes3.magicSchool.mysticism)
	end,
	tooltip = {
		text = common.i18n("filter.mysticism.text"),
		helpText = common.i18n("filter.mysticism.helpText"),
	},
	icon = "icons/ui_exp/magic_mysticism.tga",
})

magicFilters:addFilter({
	key = "restoration",
	callback = function(e)
		return getEffectsContainsSchool(e.effects, tes3.magicSchool.restoration)
	end,
	tooltip = {
		text = common.i18n("filter.restoration.text"),
		helpText = common.i18n("filter.restoration.helpText"),
	},
	icon = "icons/ui_exp/magic_restoration.tga",
})

--- Add spell icons to a list.
--- @param spellsList tes3uiElement
--- @param guiIdPrefix string
--- @param namesBlockId string
--- @param isSpell boolean
local function addSpellIcons(spellsList, guiIdPrefix, namesBlockId, isSpell)
	local namesBlock = spellsList:findChild(namesBlockId)

	-- Create icons column.
	local columnsBlock = namesBlock.parent
	local iconsColumn =
	columnsBlock:createBlock({ id = string.format("UIEXP:MagicMenu:SpellsList:%s:Icons", guiIdPrefix) })
	iconsColumn.flowDirection = "top_to_bottom"
	iconsColumn.autoWidth = true
	iconsColumn.autoHeight = true
	iconsColumn.paddingRight = 4
	iconsColumn.paddingLeft = 2
	columnsBlock:reorderChildren(0, -1, 1)

	-- Find and create icons for the available spells.
	if (isSpell) then
		for _, nameElement in ipairs(namesBlock.children) do
			local spell = nameElement:getPropertyObject("MagicMenu_Spell")
			local icon = iconsColumn:createImage({ path = string.format("icons\\%s", spell.effects[1].object.icon) })
			icon.borderTop = 2
			icon:setPropertyObject("MagicMenu_Spell", spell)
			icon:register("mouseClick", function()
				nameElement:triggerEvent("mouseClick")
			end)
			icon:register("help", function()
				nameElement:triggerEvent("help")
			end)
			icon.visible = nameElement.visible
		end
	else
		for _, nameElement in ipairs(namesBlock.children) do
			local object = nameElement:getPropertyObject("MagicMenu_object")
			local icon = iconsColumn:createImage({ path = string.format("icons\\%s", object.enchantment.effects[1].object.icon)  })
			icon.borderTop = 2
			icon:setPropertyObject("MagicMenu_object", object)
			icon:register("mouseClick", function()
				nameElement:triggerEvent("mouseClick")
			end)
			icon:register("help", function()
				nameElement:triggerEvent("help")
			end)
			icon.visible = nameElement.visible
		end
	end
end

--- Removes spell icons from a list.
--- @param spellsList tes3uiElement
--- @param guiIdPrefix string
--- @param namesBlockId string
local function removeSpellIcons(spellsList, guiIdPrefix, namesBlockId)
	local namesBlock = spellsList:findChild(namesBlockId)
	local iconColumn = namesBlock.parent:findChild(string.format("UIEXP:MagicMenu:SpellsList:%s:Icons", guiIdPrefix))
	if (iconColumn) then
		iconColumn:destroy()
	end
end

-- Updates spell icons for powers, spells, and items.
local function updateSpellIcons()
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
	if (not magicMenu) then
		return
	end

	local spellsList = magicMenu:findChild(GUI_ID_MagicMenu_spells_list)

	-- Delete current spell icons.
	removeSpellIcons(spellsList, "Powers", "MagicMenu_power_names")
	removeSpellIcons(spellsList, "Spells", "MagicMenu_spell_names")
	removeSpellIcons(spellsList, "Items", "MagicMenu_item_names")

	-- Create spell icons.
	addSpellIcons(spellsList, "Powers", "MagicMenu_power_names", true)
	addSpellIcons(spellsList, "Spells", "MagicMenu_spell_names", true)
	addSpellIcons(spellsList, "Items", "MagicMenu_item_names", false)
end

--- Grays out or restores powers based on if they are available.
local function updatePowerUsability()
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
	if (not magicMenu) then
		return
	end

	local powersList = magicMenu:findChild(GUI_ID_MagicMenu_spells_list):findChild("MagicMenu_power_names")
	for _, nameElement in ipairs(powersList.children) do
		local power = nameElement:getPropertyObject("MagicMenu_Spell")
		if (tes3.mobilePlayer:hasUsedPower(power)) then
			nameElement.widget.idle = tes3ui.getPalette("disabled_color")
		else
			nameElement.widget.idle = tes3ui.getPalette("normal_color")
		end
	end
end

--- Updates all magic menu features.
local function updateMagicMenu()
	updateSpellIcons()
	updatePowerUsability()
	event.trigger("UIEXP:magicMenuPreUpdate")
end

--- Create our changes for MenuMagic.
--- @param e uiActivatedEventData
local function onMenuMagicActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local spellsList = e.element:findChild(GUI_ID_MagicMenu_spells_list)

	-- Make the parent block order from top to bottom.
	local spellsListParent = spellsList.parent
	spellsListParent.flowDirection = "top_to_bottom"

	-- Make a consistent container and move it to the top of the block.
	local filterBlock = spellsListParent:createBlock({ id = "UIEXP:MagicMenu:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4
	spellsListParent:reorderChildren(0, -1, 1)

	-- Actually create our filter elements.
	magicFilters:createElements(filterBlock)

	-- Create spell icons.
	addSpellIcons(spellsList, "Powers", "MagicMenu_power_names", true)
	addSpellIcons(spellsList, "Spells", "MagicMenu_spell_names", true)

	-- Listen for future pre-updates to refresh spell icons.
	e.element:registerAfter("preUpdate", updateMagicMenu)
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" })

--- Update filters when entering menu mode.
local function onEnterMenuMode()
	if (common.config.alwaysClearFiltersOnOpen) then
		magicFilters:clearFilter()
	end

	if (common.config.autoSelectInput == "Magic") then
		magicFilters:focusSearchBar()
	end
end
event.register("menuEnter", onEnterMenuMode, { filter = "MenuInventory" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMagic" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuMap" })
event.register("menuEnter", onEnterMenuMode, { filter = "MenuStat" })

--
-- Update power used colors on cast/when recharged.
--

--- Gets the element for a given power.
--- @param power tes3spell
--- @return tes3uiElement
local function getNameBlockForPower(power)
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
	if (not magicMenu) then
		return
	end

	local powersList = magicMenu:findChild(GUI_ID_MagicMenu_spells_list):findChild("MagicMenu_power_names")
	for _, nameElement in ipairs(powersList.children) do
		if (nameElement:getPropertyObject("MagicMenu_Spell") == power) then
			return nameElement
		end
	end
end

--- Gray out powers when they are cast.
--- @param e spellCastedEventData
local function onSpellCasted(e)
	if (e.caster == tes3.player and e.source.castType == tes3.spellType.power) then
		local nameElement = getNameBlockForPower(e.source)
		if (nameElement) then
			nameElement.widget.idle = tes3ui.getPalette("normal_color")
		end
	end
end
event.register("spellCasted", onSpellCasted)

--- Restores power color when it is recharged.
--- @param e powerRechargedEventData
local function onPowerRecharged(e)
	if (e.mobile == tes3.mobilePlayer) then
		local nameElement = getNameBlockForPower(e.power)
		if (nameElement) then
			nameElement.widget.idle = tes3ui.getPalette("disabled_color")
		end
	end
end
event.register("powerRecharged", onPowerRecharged)
