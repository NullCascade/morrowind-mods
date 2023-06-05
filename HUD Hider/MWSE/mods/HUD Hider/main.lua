--[[

	Allows using a simple key to toggle the HUD.

--]]

local hudIsVisible = true

local config = mwse.loadConfig("HUD Hider")
config = config or {}
config.toggleKey = config.toggleKey or {
	keyCode = tes3.scanCode.closeSquareBracket,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = true
}

local function keybindTest(b, e)
	return (b.keyCode == e.keyCode) and (b.isShiftDown == e.isShiftDown) and (b.isAltDown == e.isAltDown) and (b.isControlDown == e.isControlDown)
end

local previousShownState = true
local function setCrosshairShown(show)
	if (show and tes3.worldController.cursorOff) then
		tes3.worldController.cursorOff = previousShownState
		tes3.worldController.nodeCursor.appCulled = previousShownState
	elseif (not show and not tes3.worldController.cursorOff) then
		previousShownState = tes3.worldController.cursorOff
		tes3.worldController.cursorOff = true
		tes3.worldController.nodeCursor.appCulled = true
	end
end

local function setHudHidden(hidden)
	hudIsVisible = not hidden

	-- All the code needed to actually toggle the HUD.
	local menuMulti = tes3ui.findMenu("MenuMulti")
	if (menuMulti) then
		menuMulti.visible = hudIsVisible
		menuMulti:updateLayout()
	end

	local tooltip = tes3ui.findHelpLayerMenu("HelpMenu")
	if (tooltip) then
		tooltip.visible = hudIsVisible
		tooltip:updateLayout()
	end

	setCrosshairShown(hudIsVisible)
end

local function onKeyDown(e)
	if (not keybindTest(config.toggleKey, e)) then
		return
	end

	setHudHidden(hudIsVisible)
end
event.register("keyDown", onKeyDown)

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
	if (hudIsVisible) then
		return
	end

	e.tooltip.visible = false
	e.tooltip:updateLayout()
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)

--- @param e menuExitEventData
local function menuExitCallback(e)
	if (hudIsVisible) then
		return
	end

	setHudHidden(true)
end
event.register(tes3.event.menuExit, menuExitCallback)

local function registerModConfig()
	local easyMCM = include("easyMCM.EasyMCM")
	if (easyMCM == nil) then
		return
	end

	local template = easyMCM.createTemplate("HUD Hider")
	template:saveOnClose("HUD Hider", config)

	local page = template:createPage()
	page:createKeyBinder{
		label = "Assign Keybind",
		allowCombinations = true,
		variable = easyMCM.createTableVariable{
			id = "toggleKey",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.closeSquareBracket,
				isShiftDown = false,
				isAltDown = false,
				isControlDown = true,
			}
		}
	}

	easyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)
