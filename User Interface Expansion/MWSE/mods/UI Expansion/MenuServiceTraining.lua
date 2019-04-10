local common = require("UI Expansion.common")
local lasttarget

local function onAfterTrainTimer()
	if(tes3.menuMode()) then
		timer.start({ duration = 0.3, callback = onAfterTrainTimer })
	else
		if(lasttarget ~= nil) then		
			tes3.player:activate(lasttarget)
			local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
			local trainbtn = menu:findChild(tes3ui.registerID("MenuDialog_service_training"))
			trainbtn:triggerEvent("mouseClick")
		end	
	end
end

local function openTraining(e)
	e.source:forwardEvent(e)
	timer.start({ duration = 0.3, callback = onAfterTrainTimer })
end

local function menuTraining(e)
	--local scp = e.element:findChild(tes3ui.registerID("PartScrollPane_Pane"))
	local scp = e.element.children[2].children[3].children[1].children[1]
	for i,v in ipairs(scp.children) do 
		v.children[1]:register("mouseClick", openTraining)
	end
	lasttarget = tes3ui.getServiceActor().reference
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	menu.visible = false
end

event.register("uiActivated", menuTraining, { filter = "MenuServiceTraining"})