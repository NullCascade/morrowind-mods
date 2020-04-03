-- As soon as the map menu is activated, destroy it.
local function onMenuMapActivated(e)
	e.element.absolutePosAlignX = 4.0
end
event.register("uiActivated", onMenuMapActivated, { filter = "MenuMap" })

-- When the multi-menu is created, hide the minimap.
local function onMenuMultiActivated(e)
	local mapNotify = e.element:findChild(tes3ui.registerID("MenuMulti_map_notify"))
	mapNotify.borderAllSides = -100
	e.element:findChild(tes3ui.registerID("MenuMap_panel")).parent.visible = false
end
event.register("uiActivated", onMenuMultiActivated, { filter = "MenuMulti" })
