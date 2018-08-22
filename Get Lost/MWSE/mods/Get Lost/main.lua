
-- When we enter menu mode we disable the map menu.
local function onMenuMapActivated(e)
	local menuMap = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
	if (menuMap) then
		menuMap.visible = false
	end
end
event.register("menuEnter", onMenuMapActivated)

-- When the multi-menu is created, hide the minimap.
local function onMenuMultiActivated(e)
	e.element:findChild(tes3ui.registerID("MenuMap_panel")).parent.visible = false
end
event.register("uiActivated", onMenuMultiActivated, { filter = "MenuMulti" })
