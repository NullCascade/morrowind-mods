local common = require("UI Expansion.common")

local GUIID_MenuMap_switch = tes3ui.registerID("MenuMap_switch")
local MenuMap_switch = nil

local function changeCell(e)
	if (MenuMap_switch == nil) then
		return
	end

	if (e.cell.isInterior ~= true and MenuMap_switch.text == tes3.findGMST(tes3.gmst.sWorld).value) then
		MenuMap_switch:triggerEvent("mouseClick")
	end
	if (e.cell.isInterior and MenuMap_switch.text == tes3.findGMST(tes3.gmst.sLocal).value) then
		MenuMap_switch:triggerEvent("mouseClick")
	end
end
event.register("cellChanged", changeCell)


local function onKeyInput()
	if (common.complexKeybindTest(common.config.keybindMapSwitch)) then
		MenuMap_switch:triggerEvent("mouseClick")
	end
end
event.register("keyDown", onKeyInput)

local function onMapCreated(e)
	MenuMap_switch = e.element:findChild(GUIID_MenuMap_switch)
end
event.register("uiActivated", onMapCreated, { filter = "MenuMap" } )