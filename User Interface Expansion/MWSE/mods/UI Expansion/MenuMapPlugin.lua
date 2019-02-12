local common = require("UI Expansion.common")

-- Hook map changes.
local extern = include("uiextension")
if (extern == nil) then
	return
end

local currentZoom = 1.0
local zoomBar = nil

local function onMapMenuActivated(e)
	local mapMenu = e.element

	local newBottomBlock = mapMenu:createBlock({})
	newBottomBlock.autoWidth = true
	newBottomBlock.autoHeight = true
	newBottomBlock.absolutePosAlignX = 1.0
	newBottomBlock.absolutePosAlignY = 1.0

	-- The world map itself. Cache it here to show/hide the zoom bar based on this element's visibility.
	local worldMap = mapMenu:findChild(tes3ui.registerID("MenuMap_world"))

	-- Create a horizontal bar that lets us zoom in/out.
	zoomBar = newBottomBlock:createSlider({ current = 0, max = 300, step = 1, jump = 10 })
	zoomBar.absolutePosAlignY = 0.5
	zoomBar.width = 300
	zoomBar:register("PartScrollBar_changed", function(e)
		currentZoom = zoomBar:getPropertyInt("PartScrollBar_current")/100 + 1.0
		extern.setMapZoom(currentZoom)
	end)
	extern.setMapZoom(currentZoom)

	-- Find the old button so we can reuse it.
	local oldButton = mapMenu:findChild(tes3ui.registerID("MenuMap_switch"))
	oldButton.visible = false

	-- Create a new button in a new container, and map it to the old map switch button.
	local newSwitchButton = newBottomBlock:createButton({})
	newSwitchButton.text = oldButton.text
	newSwitchButton:register("mouseClick", function()
		oldButton:triggerEvent("mouseClick")
		newSwitchButton.text = oldButton.text
		zoomBar.visible = worldMap.visible
	end)
end
event.register("uiActivated", onMapMenuActivated, { filter = "MenuMap" })

local function onMouseWheel(e)
	if (tes3.getTopMenu().name ~= "MenuMap") then
		return
	end

	if (e.delta == 0) then
		return
	end

	zoomBar.widget.current = math.clamp(zoomBar.widget.current + 10 * e.delta/math.abs(e.delta), 0, 300)
	zoomBar:triggerEvent("PartScrollBar_changed")
	zoomBar:getTopLevelParent():updateLayout()
	zoomBar:updateLayout()
end
event.register("mouseWheel", onMouseWheel)
