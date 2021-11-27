
local GUI_ID_MenuMagic = tes3ui.registerID("MenuMagic")
local GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")

local common = require("UI Expansion.common")
local commonMagic = require("UI Expansion.commonMagic")

----------------------------------------------------------------------------------------------------
-- Spell List: Filtering and Searching
----------------------------------------------------------------------------------------------------

local magicFilters = commonMagic.createMagicFilterInterface({
	name = "magic",
	menu = "MenuMagic",
})

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
	commonMagic.addSpellIcons(spellsList, "Powers", "MagicMenu_power_names", true)
	commonMagic.addSpellIcons(spellsList, "Spells", "MagicMenu_spell_names", true)
	commonMagic.addSpellIcons(spellsList, "Items", "MagicMenu_item_names", false)
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
	commonMagic.addSpellIcons(spellsList, "Powers", "MagicMenu_power_names", true)
	commonMagic.addSpellIcons(spellsList, "Spells", "MagicMenu_spell_names", true)

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
