local common = require("UI Expansion.common")

local currentZoom = 2.0
local zoomBar = nil

-- Check for plugin.
local externMapPlugin = include("uiexp_map_extension")
if (externMapPlugin == nil) then
	local warningMsg = common.i18n("mapExtension.pluginNotFound")
	mwse.log(warningMsg)
	tes3.messageBox(warningMsg)
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
	zoomBar:triggerEvent(tes3.uiEvent.partScrollBarChanged)
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
	local zoomIcon = newBottomBlock:createImage{ path = "Icons\\ui_exp\\map_zoom.dds" }
	zoomIcon:register(tes3.uiEvent.mouseClick, function()
		setZoomBar(100)
	end)

	-- Create a horizontal bar that lets us zoom in/out.
	zoomBar = newBottomBlock:createSlider{ current = (currentZoom - 1) * 100, max = 300, step = 1, jump = 10 }
	zoomBar.absolutePosAlignY = 0.5
	zoomBar.width = 300
	zoomBar.borderRight = 12
	zoomBar:register(tes3.uiEvent.partScrollBarChanged, function()
		currentZoom = zoomBar:getPropertyInt("PartScrollBar_current") / 100 + 1.0
		externMapPlugin.setMapZoom(currentZoom)
	end)
	externMapPlugin.setMapZoom(currentZoom)

	-- Create a button to centre the map on the player.
	local recenterButton = newBottomBlock:createButton{ text = common.i18n("mapExtension.recenter") }
	recenterButton.borderTop = 6
	recenterButton:register(tes3.uiEvent.mouseClick, externMapPlugin.centerOnPlayer)
	
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

-- Map region redraw code used by MCM.

local mapRedrawData = {}

local function updateRegionHighlight()
	local mapMenu = tes3ui.findMenu("MenuMap")
	local highlight = mapMenu:findChild("UIEXP:MapRedrawHighlight")
	
	local mapConfig = common.config.mapConfig
	local scale = mapConfig.cellResolution * currentZoom
	highlight.positionX = (mapRedrawData.minX - mapConfig.minX) * scale
	highlight.positionY = (mapRedrawData.maxY - mapConfig.maxY) * scale
	highlight.width = math.max(0, mapRedrawData.maxX - mapRedrawData.minX + 1) * scale
	highlight.height = math.max(0, mapRedrawData.maxY - mapRedrawData.minY + 1) * scale
	
	mapMenu:updateLayout()
end

common.createMapRedrawMenu = function(e)
	local mapMenu = tes3ui.findMenu("MenuMap")
	if not mapMenu then return end
	
	-- Set up initial state.
	local mapConfig = common.config.mapConfig
	mapRedrawData = { minX = -1, maxX = 1, minY = -1, maxY = 1 }

	-- Show world map.
	mapMenu.visible = true
	mapMenu:updateLayout()
	tes3ui.moveMenuToFront(mapMenu)

	-- Create selection highlight on world map.
	local worldMap = mapMenu:findChild("MenuMap_world_map")
	local highlight = worldMap:createRect{ id = "UIEXP:MapRedrawHighlight" }
	highlight.consumeMouseEvents = false
	highlight.ignoreLayoutX = true
	highlight.ignoreLayoutY = true
	highlight.color = { 0.8, 0.8, 1 }
	highlight.alpha = 0.16
	updateRegionHighlight()
	
	-- Update highlight when zoom changes.
	zoomBar:registerAfter(tes3.uiEvent.partScrollBarChanged, updateRegionHighlight)
	highlight:registerBefore(tes3.uiEvent.destroy, function(e)
		zoomBar:unregisterAfter(tes3.uiEvent.partScrollBarChanged, updateRegionHighlight)
	end)

	-- Create region select menu.
	local menu = tes3ui.createMenu{ id = "UIEXP:MapRedrawMenu", dragFrame = true }
	menu.text = common.i18n("mapExtension.redraw.title")
	menu.width = 720
	menu.height = 210
	
	local note = menu:createLabel{ text = common.i18n("mapExtension.redraw.note") }
	note.absolutePosAlignX = 0.5
	note.borderBottom = 10

	local blockX = menu:createBlock{}
	blockX.widthProportional = 1
	blockX.autoHeight = true
	blockX.flowDirection = tes3.flowDirection.leftToRight

	local sliderMinX = mwse.mcm.createSlider(blockX, {
		label = common.i18n("mcm.mapExtension.minX.label"),
		current = -1,
		min = mapConfig.minX,
		max = mapConfig.maxX,
		variable = mwse.mcm.createTableVariable{ id = "minX", table = mapRedrawData },
		callback = updateRegionHighlight,
	})
	local sliderMaxX = mwse.mcm.createSlider(blockX, {
		label = common.i18n("mcm.mapExtension.maxX.label"),
		current = -1,
		min = mapConfig.minX,
		max = mapConfig.maxX,
		variable = mwse.mcm.createTableVariable{ id = "maxX", table = mapRedrawData },
		callback = updateRegionHighlight,
	})

	local blockY = menu:createBlock{}
	blockY.widthProportional = 1
	blockY.autoHeight = true
	blockY.flowDirection = tes3.flowDirection.leftToRight

	local sliderMinY = mwse.mcm.createSlider(blockY, {
		label = common.i18n("mcm.mapExtension.minY.label"),
		current = -1,
		min = mapConfig.minY,
		max = mapConfig.maxY,
		variable = mwse.mcm.createTableVariable{ id = "minY", table = mapRedrawData },
		callback = updateRegionHighlight,
	})
	local sliderMaxY = mwse.mcm.createSlider(blockY, {
		label = common.i18n("mcm.mapExtension.maxY.label"),
		current = -1,
		min = mapConfig.minY,
		max = mapConfig.maxY,
		variable = mwse.mcm.createTableVariable{ id = "maxY", table = mapRedrawData },
		callback = updateRegionHighlight,
	})

	local buttonBlock = menu:createBlock{}
	buttonBlock.absolutePosAlignX = 1
	buttonBlock.autoWidth = true
	buttonBlock.height = 30
	buttonBlock.borderTop = 20
	buttonBlock.borderRight = 12
	buttonBlock.flowDirection = tes3.flowDirection.leftToRight
	
	local redrawButton = buttonBlock:createButton{ text = common.i18n("mapExtension.redraw.execute.buttonName") }
	redrawButton:register(tes3.uiEvent.mouseClick, function(e)
		tes3.messageBox(common.i18n("mapExtension.redraw.redrawNotify"))
		externMapPlugin.redrawCellRect(mapRedrawData)
	end)
	local doneButton = buttonBlock:createButton{ text = tes3.findGMST(tes3.gmst.sDone).value }
	doneButton:register(tes3.uiEvent.mouseClick, function(e)
		highlight:destroy()
		mapMenu.visible = false
		mapMenu:updateLayout()
		menu:destroy()
	end)
	
	menu:updateLayout()
end
