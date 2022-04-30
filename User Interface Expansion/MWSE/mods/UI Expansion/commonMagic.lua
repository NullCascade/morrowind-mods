local commonMagic = {}

local common = require("UI Expansion.common")

local GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")

--- Add spell icons to a list.
--- @param spellsList tes3uiElement
--- @param guiIdPrefix string
--- @param namesBlockId string
--- @param isSpell boolean
function commonMagic.addSpellIcons(spellsList, guiIdPrefix, namesBlockId, isSpell)
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

--- @type tes3uiElement
local firstSearchResult = nil

--- Helper function to search element text.
--- @param titleElement tes3uiElement
--- @param listElement tes3uiElement
--- @param isSpellFilter boolean
--- @return boolean
function commonMagic.searchSubList(titleElement, listElement, isSpellFilter)
	-- Gather a list of all the columns/rows so we don't have to keep creating tables later.
	local columnElements = {}
	for _, element in ipairs(listElement.children) do
		table.insert(columnElements, element.children)
	end

	local filterName = titleElement:getTopLevelMenu().name == "MenuMagic" and "magic" or "magicSelect"

	-- Go through and compare each element in listElement to our filter.
	local matchCount = 0
	for i, nameElement in ipairs(columnElements[1]) do
		local filterObject = nameElement:getPropertyObject(isSpellFilter and "MagicMenu_Spell" or "MagicMenu_object")
		local filter = common.allFilters[filterName]:triggerFilter({
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
function commonMagic.searchSpellsList(magicMenu)
	-- Clear first search result hit.
	firstSearchResult = nil

	-- Get magic menu.
	if (not magicMenu) then
		debug.log("test")
		return
	end

	-- Get spells list.
	local spellsList = magicMenu:findChild(GUI_ID_MagicMenu_spells_list)
	if (not spellsList) then
		debug.log("test")
		return
	end

	-- Filter all of our sub groups.
	local elements = spellsList.widget.contentPane.children
	local hasMatchingPowers = commonMagic.searchSubList(elements[1], elements[2], true)
	local hasMatchingSpells = commonMagic.searchSubList(elements[4], elements[5], true)
	local hasMatchingItems = commonMagic.searchSubList(elements[7], elements[8], false)

	-- Figure out dividers.
	elements[3].visible = (hasMatchingPowers and hasMatchingSpells)
	elements[6].visible = (hasMatchingSpells and hasMatchingItems or
	                      (not hasMatchingSpells and hasMatchingPowers and hasMatchingItems))

	if (magicMenu.name == "MenuMagic" and common.allFilters.magic.searchText and common.config.selectSpellsOnSearch and firstSearchResult) then
		firstSearchResult:triggerEvent("mouseClick")
	end
end

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

function commonMagic.createMagicFilterInterface(params)
	local magicFilters = common.createFilterInterface({
		filterName = params.name,
		createSearchBar = true,
		createIcons = true,
		createButtons = false,
		useIcons = true,
		useSearch = common.config.useSearch,
		onFilterChanged = function()
			commonMagic.searchSpellsList(tes3ui.findMenu(params.menu))
		end,
	})

	magicFilters:addFilter({
		key = "alteration",
		callback = function(e)
			return getEffectsContainsSchool(e.effects, tes3.magicSchool.alteration)
		end,
		tooltip = {
			text = common.i18n("filter.effect.helpDescription", { "alteration" }),
			helpText = common.i18n("filter.effect.help.helpText", { "alteration" }),
		},
		icon = "icons/ui_exp/magic_alteration.tga",
	})

	magicFilters:addFilter({
		key = "conjuration",
		callback = function(e)
			return getEffectsContainsSchool(e.effects, tes3.magicSchool.conjuration)
		end,
		tooltip = {
			text = common.i18n("filter.effect.helpDescription", { "conjuration" }),
			helpText = common.i18n("filter.effect.help.helpText", { "conjuration" }),
		},
		icon = "icons/ui_exp/magic_conjuration.tga",
	})

	magicFilters:addFilter({
		key = "destruction",
		callback = function(e)
			return getEffectsContainsSchool(e.effects, tes3.magicSchool.destruction)
		end,
		tooltip = {
			text = common.i18n("filter.effect.helpDescription", { "destruction" }),
			helpText = common.i18n("filter.effect.help.helpText", { "destruction" }),
		},
		icon = "icons/ui_exp/magic_destruction.tga",
	})

	magicFilters:addFilter({
		key = "illusion",
		callback = function(e)
			return getEffectsContainsSchool(e.effects, tes3.magicSchool.illusion)
		end,
		tooltip = {
			text = common.i18n("filter.effect.helpDescription", { "illusion" }),
			helpText = common.i18n("filter.effect.help.helpText", { "illusion" }),
		},
		icon = "icons/ui_exp/magic_illusion.tga",
	})

	magicFilters:addFilter({
		key = "mysticism",
		callback = function(e)
			return getEffectsContainsSchool(e.effects, tes3.magicSchool.mysticism)
		end,
		tooltip = {
			text = common.i18n("filter.effect.helpDescription", { "mysticism" }),
			helpText = common.i18n("filter.effect.help.helpText", { "mysticism" }),
		},
		icon = "icons/ui_exp/magic_mysticism.tga",
	})

	magicFilters:addFilter({
		key = "restoration",
		callback = function(e)
			return getEffectsContainsSchool(e.effects, tes3.magicSchool.restoration)
		end,
		tooltip = {
			text = common.i18n("filter.effect.helpDescription", { "restoration" }),
			helpText = common.i18n("filter.effect.help.helpText", { "restoration" }),
		},
		icon = "icons/ui_exp/magic_restoration.tga",
	})

	return magicFilters
end

return commonMagic
