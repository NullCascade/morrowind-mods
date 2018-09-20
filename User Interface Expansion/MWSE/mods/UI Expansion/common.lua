local common = {}

function common.createSearchBar(params)
	local border = params.parent:createThinBorder({})
	border.autoWidth = true
	border.autoHeight = true
	border.widthProportional = 1.0

	-- Create the search input itself.
	local input = border:createTextInput({ id = tes3ui.registerID(params.id) })
	input.color = tes3ui.getPalette("disabled_color")
	input.text = params.placeholderText
	input.borderLeft = 5
	input.borderRight = 5
	input.borderTop = 2
	input.borderBottom = 4
	input.widget.eraseOnFirstKey = true
	input.widget.lengthLimit = 31

	-- Set up the events to control text input control.
	input.consumeMouseEvents = false
	input:register("keyPress", function(e)
		-- Prevent alt-tabbing from creating spacing.
		if (tes3.worldController.inputController:isKeyPressedThisFrame(15)) then
			return
		end

		input:forwardEvent(e)

		input.color = tes3ui.getPalette("normal_color")
		params.onUpdate(e)
	end)
	border:register("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)

	return { border = border, input = input }
end

return common