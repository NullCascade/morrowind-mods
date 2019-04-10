
-- As soon as the map menu is activated, destroy it.
local function onMenuMapActivated(e)
	if (tes3.getGlobal("CharGenState") < 0) then
		e.element:destroy()
	else
		timer.delayOneFrame(function() e.element:destroy() end)
	end
end
event.register("uiActivated", onMenuMapActivated, { filter = "MenuMap" })

-- When the multi-menu is created, hide the minimap.
local function onMenuMultiActivated(e)
	e.element:findChild(tes3ui.registerID("MenuMap_panel")).parent.visible = false
end
event.register("uiActivated", onMenuMultiActivated, { filter = "MenuMulti" })
