local common = require("UI Expansion.lib.common")

local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")

--- Create our changes for MenuQuantity.
--- @param e uiActivatedEventData
local function menuQuantity(e)
	-- Enable keyboard support for the scroll bar.
	local scrollBar = e.element:findChild("MenuQuantity_scrollbar")
	local submitButton = e.element:findChild("MenuQuantity_buttonok")
	common.bindScrollBarToKeyboard({
		element = scrollBar,
		onSubmit = function()
			submitButton:triggerEvent(tes3.uiEvent.mouseClick)
		end,
	})

	-- Register event so that when mouseClick happens on ok button an update event is
	-- sent to the contents menu.
	local contentsMenu = tes3ui.findMenu(GUI_ID_MenuContents)
	if (contentsMenu) then
		submitButton:registerAfter(tes3.uiEvent.mouseClick, function()
			contentsMenu:triggerEvent(tes3.uiEvent.update)
		end)
	end
end
event.register(tes3.event.uiActivated, menuQuantity, { filter = "MenuQuantity" })
