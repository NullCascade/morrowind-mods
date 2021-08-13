local function onKeyDownCopyCut(e)
	if (not e.isControlDown or e.isShiftDown or e.isSuperDown) then
		return
	end

	-- Get our input element.
	local menuInputController = tes3.worldController.menuController.inputController
	local inputFocus = tes3.worldController.menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Make sure the buffer gets cleared so no text makes it to the focused element.
	menuInputController:flushBufferedTextEvents()

	-- Figure out where our cursor is.
	local inputFocusText = inputFocus.rawText
	local cursorPosition = inputFocusText and string.find(inputFocusText, "|", 1, true) or 0

	-- Figure out where we want to start copying. If we are holding alt, copy after the cursor. Otherwise copy up to it.
	local copyStart = e.isAltDown and (cursorPosition + 1) or 1
	local copyEnd = e.isAltDown and #inputFocusText or (cursorPosition - 1)

	-- Copy our text.
	local copyText = string.sub(inputFocusText, copyStart, copyEnd)
	if (not copyText or copyText == "") then
		return
	end
	os.setClipboardText(copyText)

	-- If we are cutting, clear the text.
	if (e.keyCode == tes3.scanCode.x) then
		local cutText = string.sub(inputFocusText, copyEnd + 1, #inputFocusText)
		inputFocus.rawText = cutText
		inputFocus:getTopLevelParent():updateLayout()
	end
end
event.register("keyDown", onKeyDownCopyCut, { filter = tes3.scanCode.c })
event.register("keyDown", onKeyDownCopyCut, { filter = tes3.scanCode.x })

local function onKeyDownV(e)
	if (not e.isControlDown or e.isShiftDown or e.isAltDown or e.isSuperDown) then
		return
	end

	-- Get our input element.
	local menuInputController = tes3.worldController.menuController.inputController
	local inputFocus = tes3.worldController.menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Make sure the buffer gets cleared so no text makes it to the focused element.
	menuInputController:flushBufferedTextEvents()

	-- Get clipboard text. Remove all instances of `|`. 
	local clipboardText = os.getClipboardText()
	clipboardText = clipboardText and clipboardText:gsub("|", "")
	if (not clipboardText or clipboardText == "") then
		return
	end

	-- Insert our clipboard text at the cursor position.
	local inputFocusText = inputFocus.rawText
	local cursorPosition = inputFocusText and string.find(inputFocusText, "|", 1, true) or 1
	inputFocus.text = string.insert(inputFocusText, clipboardText, cursorPosition - 1)
	inputFocus:getTopLevelParent():updateLayout()
end
event.register("keyDown", onKeyDownV, { filter = tes3.scanCode.v })
