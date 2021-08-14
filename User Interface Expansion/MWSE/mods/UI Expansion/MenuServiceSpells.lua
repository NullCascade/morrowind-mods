
--- Sorter function that compares the element's text.
--- @param a tes3uiElement
--- @param b tes3uiElement
local function textSorter(a, b)
	return a.text < b.text
end

--- Create our changes for MenuServiceSpells.
--- @param e uiActivatedEventData
local function onUIActivated(e)
	-- We only care if this is the node time it was activated.
	if (not e.newlyCreated) then
		return
	end

	local menu = e.element

	-- Sort spells list.
	local MenuServiceSpells_ServiceList = menu:findChild("MenuServiceSpells_ServiceList")
	MenuServiceSpells_ServiceList:findChild("PartScrollPane_pane"):sortChildren(textSorter)
	MenuServiceSpells_ServiceList:updateLayout()

	-- TODO: Add spell icons.

	-- Finish up.
	menu:updateLayout()
end
event.register("uiActivated", onUIActivated, { filter = "MenuServiceSpells" })
