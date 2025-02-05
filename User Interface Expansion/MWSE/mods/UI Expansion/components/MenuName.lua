--- @param e uiActivatedEventData
local function onMenuNameActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local input = e.element:findChild("MenuName_NameSpace")
	local border = input.parent

	input.consumeMouseEvents = false
	border:registerAfter(tes3.uiEvent.mouseClick, function()
		tes3ui.acquireTextInput(input)
	end)
end
event.register(tes3.event.uiActivated, onMenuNameActivated, { filter = "MenuName" })
