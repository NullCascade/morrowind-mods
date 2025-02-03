--- Resizes the button width to match the given texture, so it aligns right and doesn't clip.
--- @param parent tes3uiElement
--- @param id string
local function resizeContainer(parent, id)
	local button = parent:findChild(id)
	if (button) then
		local texture = button.children[1].texture
		if (texture) then
			button.width = texture.width
		end
	end
end

--- Create our changes for MenuOptions.
--- @param e uiActivatedEventData
local function onCreatedMenuOptions(e)
	-- Only interested in menu creation, not updates
	if (not e.newlyCreated) then
		return
	end

	local mainMenu = e.element

	resizeContainer(mainMenu, "MenuOptions_Return_container")
	resizeContainer(mainMenu, "MenuOptions_New_container")
	resizeContainer(mainMenu, "MenuOptions_Save_container")
	resizeContainer(mainMenu, "MenuOptions_Load_container")
	resizeContainer(mainMenu, "MenuOptions_Options_container")
	resizeContainer(mainMenu, "MenuOptions_Credits_container")
	resizeContainer(mainMenu, "MenuOptions_Exit_container")

	mainMenu.autoWidth = true

	mainMenu:updateLayout()
end
event.register("uiActivated", onCreatedMenuOptions, { filter = "MenuOptions" })
