local common = require("UI Expansion.common")

local GUIID_MenuMap = tes3ui.registerID("MenuMap")
local GUIID_MenuMap_switch = tes3ui.registerID("MenuMap_switch")

local function changeCell(e)
	if (not common.config.changeMapModeOnCellChange) then
		return
	end

	local MenuMap = tes3ui.findMenu(GUIID_MenuMap)
	if (MenuMap == nil) then
		return
	end

	local MenuMap_switch = MenuMap:findChild(GUIID_MenuMap_switch)
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

-- SmartMap compatibility
local lfs = require("lfs")
if lfs.attributes("Data Files/MWSE/mods/abot/Smart Map/main.lua") then
	mwse.log("[UI Expansion] MenuMap: skipping cellChanged event to be managed by abot/Smart Map");
else
	event.register("cellChanged", changeCell)
end

local function onKeyInput()
	if (common.complexKeybindTest(common.config.keybindMapSwitch)) then
		local MenuMap = tes3ui.findMenu(GUIID_MenuMap)
		if (MenuMap == nil) then
			return
		end

		local MenuMap_switch = MenuMap:findChild(GUIID_MenuMap_switch)
		if MenuMap_switch then
			MenuMap_switch:triggerEvent("mouseClick")
		end
	end
end
event.register("keyDown", onKeyInput)
