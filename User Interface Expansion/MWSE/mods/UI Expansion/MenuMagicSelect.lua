
local common = require("UI Expansion.common")
local commonMagic = require("UI Expansion.commonMagic")

local magicFilters = commonMagic.createMagicFilterInterface({
	name = "magicSelect",
	menu = "MenuMagicSelect",
})

--- Create our changes for MenuMagic.
--- @param e uiActivatedEventData
local function onMenuMagicActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local spellsList = e.element:findChild("MagicMenu_spells_list")

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
	commonMagic.addSpellIcons(spellsList, "Items", "MagicMenu_item_names", false)
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagicSelect" })
