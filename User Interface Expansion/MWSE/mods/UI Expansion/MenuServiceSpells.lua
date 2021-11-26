
--- Create our changes for MenuServiceSpells.
--- @param e uiActivatedEventData
local function onUIActivated(e)
	-- We only care if this is the node time it was activated.
	if (not e.newlyCreated) then
		return
	end

	local menu = e.element
	local MenuServiceSpells_ServiceList = menu:findChild("MenuServiceSpells_ServiceList")
	local MenuServiceSpells_ServiceList_PartScrollPane_pane = MenuServiceSpells_ServiceList:findChild("PartScrollPane_pane")
	local MenuServiceSpells_Spell = tes3ui.registerProperty("MenuServiceSpells_Spell")

	-- Get a list of spells the actor can sell from the existing UI elements.
	local serviceSpells = {} --- @type tes3spell[]
	for _, child in ipairs(MenuServiceSpells_ServiceList_PartScrollPane_pane.children) do
		table.insert(serviceSpells, child:getPropertyObject(MenuServiceSpells_Spell))
	end
	table.sort(serviceSpells, function(a, b) return a.name < b.name end)

	-- Recreate the spells list menu with multiple columns.
	MenuServiceSpells_ServiceList_PartScrollPane_pane:destroyChildren()
	MenuServiceSpells_ServiceList_PartScrollPane_pane.flowDirection = "left_to_right"
	local MenuServiceSpells_Icons = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Icons" })
	MenuServiceSpells_Icons.flowDirection = "top_to_bottom"
	MenuServiceSpells_Icons.autoWidth = true
	MenuServiceSpells_Icons.autoHeight = true
	MenuServiceSpells_Icons.paddingRight = 4
	MenuServiceSpells_Icons.paddingLeft = 2
	local MenuServiceSpells_Spells = MenuServiceSpells_ServiceList_PartScrollPane_pane:createBlock({ id = "MenuServiceSpells_Spells" })
	MenuServiceSpells_Spells.flowDirection = "top_to_bottom"
	MenuServiceSpells_Spells.autoWidth = true
	MenuServiceSpells_Spells.autoHeight = true

	-- Get some reused variables.
	local merchant = tes3ui.getServiceActor()
	local playerCurrentGold = tes3.getPlayerGold()
	local sGP = tes3.findGMST(tes3.gmst.sgp).value
	local sPoints = tes3.findGMST(tes3.gmst.spoints).value
	local MenuServiceSpells_Spell_Click = 0x616690
	local MenuServiceSpells_Spell_Help = 0x616810
	local GUI_ID_MenuServiceSpells_Icon = tes3ui.registerID("MenuServiceSpells_Icon")
	local GUI_ID_MenuServiceSpells_Spell = tes3ui.registerID("MenuServiceSpells_Spell")

	-- Fill it out.
	for _, spell in ipairs(serviceSpells) do
		local spellPrice = tes3.calculatePrice({ merchant = merchant, bartering = true, object = spell })
		local label = MenuServiceSpells_Spells:createTextSelect({ id = GUI_ID_MenuServiceSpells_Spell, text = string.format("%s (%d%s) - %d%s", spell.name, spell.magickaCost, sPoints, spellPrice, sGP) })
		label:setPropertyObject("MenuServiceSpells_Spell", spell)
		label:register("mouseClick", MenuServiceSpells_Spell_Click)
		label:register("help", MenuServiceSpells_Spell_Help)

		if (spellPrice > playerCurrentGold) then
			label.disabled = true
			label.widget.state = 2
		end
		
		local icon = MenuServiceSpells_Icons:createImage({ id = GUI_ID_MenuServiceSpells_Icon, path = string.format("icons\\%s", spell.effects[1].object.icon) })
		icon.borderTop = 2
		icon:setPropertyObject("MenuServiceSpells_Spell", spell)
		icon:register("mouseClick", MenuServiceSpells_Spell_Click)
		icon:register("help", MenuServiceSpells_Spell_Help)
	end

	-- Finish up.
	menu:updateLayout()
end
event.register("uiActivated", onUIActivated, { filter = "MenuServiceSpells" })
