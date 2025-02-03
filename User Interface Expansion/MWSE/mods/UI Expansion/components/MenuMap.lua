local common = require("UI Expansion.lib.common")

--- Update the map type on cell change.
--- @param e cellChangedEventData
local function changeCell(e)
	if (not common.config.changeMapModeOnCellChange) then return end

	local MenuMap = tes3ui.findMenu("MenuMap")
	if (MenuMap == nil) then return end

	local MenuMap_switch = MenuMap:findChild("MenuMap_switch")
	if (MenuMap_switch == nil) then return end

	if (e.previousCell == nil or e.previousCell.isInterior ~= e.cell.isInterior) then
		if (not e.cell.isInterior and MenuMap_switch.text == tes3.findGMST(tes3.gmst.sWorld).value) then
			MenuMap_switch:triggerEvent(tes3.uiEvent.mouseClick)
		elseif (e.cell.isInterior and MenuMap_switch.text == tes3.findGMST(tes3.gmst.sLocal).value) then
			MenuMap_switch:triggerEvent(tes3.uiEvent.mouseClick)
		end
	end
end

--- Allow map mode switching with a key.
local function onKeyInput()
	if (not common.isTextInputActive() and common.complexKeybindTest(common.config.keybindMapSwitch)) then
		local MenuMap = tes3ui.findMenu("MenuMap")
		if (MenuMap == nil) then return end

		local MenuMap_switch = MenuMap:findChild("MenuMap_switch")
		if MenuMap_switch then
			MenuMap_switch:triggerEvent(tes3.uiEvent.mouseClick)
		end
	end
end
event.register(tes3.event.keyDown, onKeyInput)

-- SmartMap compatibility
local lfs = require("lfs")
if lfs.attributes("Data Files/MWSE/mods/abot/Smart Map/main.lua") then
	mwse.log("[UI Expansion] MenuMap: skipping cellChanged event to be managed by abot/Smart Map");
else
	event.register(tes3.event.cellChanged, changeCell)
end