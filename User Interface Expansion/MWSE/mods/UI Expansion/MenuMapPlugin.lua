local common = require("UI Expansion.common")

-- Hook map changes.
local extern = include("uiexp_map_extension")
if (extern == nil) then
	return
end

local currentZoom = 2.0
local zoomBar = nil

local function updateNewControls()
	local mapMenu = tes3ui.findMenu("MenuMap")
	if not mapMenu then return end
	
	local worldMap = mapMenu:findChild("MenuMap_world")
	local controls = mapMenu:findChild("UIEXP:MapControls")
	local oldButton = mapMenu:findChild("MenuMap_switch")
	local newSwitchButton = controls:findChild("UIEXP:MapSwitch")

	for _, child in pairs(controls.children) do
		child.visible = worldMap.visible
	end

	newSwitchButton.text = oldButton.text
	newSwitchButton.visible = true
end

local function onMapMenuActivated(e)
	local mapMenu = e.element

	local newBottomBlock = mapMenu:createBlock{ id = "UIEXP:MapControls" }
	newBottomBlock.autoWidth = true
	newBottomBlock.autoHeight = true
	newBottomBlock.absolutePosAlignX = 1.0
	newBottomBlock.absolutePosAlignY = 1.0

	-- The world map itself. Cache it here to show/hide the zoom bar based on this element's visibility.
	local worldMap = mapMenu:findChild("MenuMap_world")

	-- Create a horizontal bar that lets us zoom in/out.
	zoomBar = newBottomBlock:createSlider{ current = (currentZoom - 1) * 100, max = 300, step = 1, jump = 10 }
	zoomBar.absolutePosAlignY = 0.5
	zoomBar.width = 300
	zoomBar.borderRight = 12
	zoomBar:register("PartScrollBar_changed", function()
		currentZoom = zoomBar:getPropertyInt("PartScrollBar_current") / 100 + 1.0
		extern.setMapZoom(currentZoom)
	end)
	extern.setMapZoom(currentZoom)

	-- Create a button to centre the map on the player.
	local recentreButton = newBottomBlock:createButton{text = common.i18n("mapExtension.recentre")}
	recentreButton:register("mouseClick", function()
		extern.centreOnPlayer()
	end)
	
	-- Find the old button so we can reuse it.
	local oldButton = mapMenu:findChild("MenuMap_switch")
	oldButton.visible = false

	-- Create a new button in a new container, and map it to the old map switch button.
	local newSwitchButton = newBottomBlock:createButton{ id = "UIEXP:MapSwitch" }
	newSwitchButton.text = oldButton.text
	newSwitchButton:register("mouseClick", function()
		oldButton:triggerEvent("mouseClick")
		updateNewControls()
	end)
end
event.register(tes3.event.uiActivated, onMapMenuActivated, { filter = "MenuMap" })

local function onEnterMenuMode(e)
	-- Update controls to reflect local map/world map state.
	updateNewControls()
end
event.register(tes3.event.menuEnter, onEnterMenuMode)

local function onMouseWheel(e)
	if (not tes3ui.menuMode()) then return end
	if (tes3.getTopMenu().name ~= "MenuMap") then return end

	local delta = e.delta
	if (delta == 0) then
		return
	end

	zoomBar.widget.current = math.clamp(zoomBar.widget.current + 10 * delta / math.abs(delta), 0, 300)
	zoomBar:triggerEvent("PartScrollBar_changed")
	zoomBar:getTopLevelParent():updateLayout()
	zoomBar:updateLayout()
end
event.register(tes3.event.mouseWheel, onMouseWheel)
