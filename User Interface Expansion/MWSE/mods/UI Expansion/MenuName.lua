--- @param e uiActivatedEventData
local function onMenuNameActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local input = e.element:findChild("MenuName_NameSpace")
	local border = input.parent

	input.consumeMouseEvents = false
	border:registerAfter("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)
end
event.register("uiActivated", onMenuNameActivated, { filter = "MenuName" })
