local common = require("UI Expansion.common")

local currentZoom = 2.0
local zoomBar = nil

-- Check for plugin.
local externMapPlugin = include("uiexp_map_extension")
if (externMapPlugin == nil) then
	return
end

-- Initialization code.
do
	-- Redraw map after all cells are loaded.
	externMapPlugin.onInitialized()

	-- Update cell bounds config.
	local data = externMapPlugin.getMapData()
	local mapConfig = common.config.mapConfig

	mapConfig.minX = data.minX
	mapConfig.minY = data.minY
	mapConfig.maxX = data.maxX
	mapConfig.maxY = data.maxY

	mwse.saveConfig("UI Expansion", common.config)
end

-- Perform map adjustments after a save is loaded.
event.register(tes3.event.loaded, externMapPlugin.onLoaded)



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

local function setZoomBar(value)
	zoomBar.widget.current = value
	zoomBar:triggerEvent("PartScrollBar_changed")
	zoomBar:getTopLevelMenu():updateLayout()
end

local function onMouseWheel(e)
	local delta = e.data0
	if (delta == 0) then
		return
	end

	setZoomBar(math.clamp(zoomBar.widget.current + 10 * delta / math.abs(delta), 0, 300))
end

local function onMapMenuActivated(e)
	local mapMenu = e.element

	local newBottomBlock = mapMenu:createBlock{ id = "UIEXP:MapControls" }
	newBottomBlock.autoWidth = true
	newBottomBlock.autoHeight = true
	newBottomBlock.absolutePosAlignX = 1.0
	newBottomBlock.absolutePosAlignY = 1.0

	-- The world map itself. Attach scrollwheel events.
	local worldMap = mapMenu:findChild("MenuMap_world")
	worldMap:registerAfter(tes3.uiEvent.mouseScrollUp, onMouseWheel)
	worldMap:registerAfter(tes3.uiEvent.mouseScrollDown, onMouseWheel)

	-- Small magnifying glass icon. Reset zoom on click.
	zoomIcon = newBottomBlock:createImage{ path = "Icons\\ui_exp\\map_zoom.dds" }
	zoomIcon:register(tes3.uiEvent.mouseClick, function()
		setZoomBar(100)
	end)

	-- Create a horizontal bar that lets us zoom in/out.
	zoomBar = newBottomBlock:createSlider{ current = (currentZoom - 1) * 100, max = 300, step = 1, jump = 10 }
	zoomBar.absolutePosAlignY = 0.5
	zoomBar.width = 300
	zoomBar.borderRight = 12
	zoomBar:register("PartScrollBar_changed", function()
		currentZoom = zoomBar:getPropertyInt("PartScrollBar_current") / 100 + 1.0
		externMapPlugin.setMapZoom(currentZoom)
	end)
	externMapPlugin.setMapZoom(currentZoom)

	-- Create a button to centre the map on the player.
	local recentreButton = newBottomBlock:createButton{ text = common.i18n("mapExtension.recentre") }
	recentreButton.borderTop = 6
	recentreButton:register(tes3.uiEvent.mouseClick, externMapPlugin.centreOnPlayer)
	
	-- Find the old button so we can reuse it.
	local oldButton = mapMenu:findChild("MenuMap_switch")
	oldButton.visible = false

	-- Create a new button in a new container, and map it to the old map switch button.
	local newSwitchButton = newBottomBlock:createButton{ id = "UIEXP:MapSwitch", text = oldButton.text }
	newSwitchButton.borderTop = 6
	newSwitchButton:register(tes3.uiEvent.mouseClick, function()
		oldButton:triggerEvent(tes3.uiEvent.mouseClick)
		updateNewControls()
	end)
end
event.register(tes3.event.uiActivated, onMapMenuActivated, { filter = "MenuMap" })

local function onEnterMenuMode(e)
	-- Update controls to reflect local map/world map state.
	updateNewControls()
end
event.register(tes3.event.menuEnter, onEnterMenuMode)
