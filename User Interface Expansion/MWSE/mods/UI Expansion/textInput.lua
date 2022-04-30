--- Handles copy/cut functionality.
--- @param e keyDownEventData
local function onKeyDownCopyCut(e)
	if (not e.isControlDown or e.isShiftDown or e.isSuperDown) then
		return
	end

	-- Get our input element.
	local menuController = tes3.worldController.menuController
	local inputFocus = menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Make sure the buffer gets cleared so no text makes it to the focused element.
	menuController.inputController:flushBufferedTextEvents()

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
		inputFocus:getTopLevelMenu():updateLayout()
	end
end
event.register("keyDown", onKeyDownCopyCut, { filter = tes3.scanCode.c })
event.register("keyDown", onKeyDownCopyCut, { filter = tes3.scanCode.x })


--- Handles paste functionality.
--- @param e keyDownEventData
local function onKeyDownV(e)
	if (not e.isControlDown or e.isShiftDown or e.isAltDown or e.isSuperDown) then
		return
	end

	-- Get our input element.
	local menuController = tes3.worldController.menuController
	local inputFocus = menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Make sure the buffer gets cleared so no text makes it to the focused element.
	menuController.inputController:flushBufferedTextEvents()

	-- Get clipboard text. Remove all instances of `|`.
	local clipboardText = os.getClipboardText()
	if (clipboardText == nil) then
		return
	end

	clipboardText = clipboardText and clipboardText:gsub("[|\r]", "")
	if (not clipboardText or clipboardText == "") then
		return
	end

	-- Insert our clipboard text at the cursor position.
	local inputFocusText = inputFocus.rawText
	local cursorPosition = inputFocusText and string.find(inputFocusText, "|", 1, true) or 1
	inputFocus.text = string.insert(inputFocusText, clipboardText, cursorPosition - 1)
	inputFocus:getTopLevelMenu():updateLayout()
end
event.register("keyDown", onKeyDownV, { filter = tes3.scanCode.v })


--- Allow home to set the input to the start of the line.
--- @param e keyDownEventData
local function onKeyDownHome(e)
	-- Get our input element.
	local inputFocus = tes3.worldController.menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Move cursor to the start.
	inputFocus.rawText = "|" .. inputFocus.rawText:gsub("|", "")
	inputFocus:getTopLevelMenu():updateLayout()
end
event.register("keyDown", onKeyDownHome, { filter = tes3.scanCode.home })


--- Allow home to set the input to the start of the line.
--- @param e keyDownEventData
local function onKeyDownEnd(e)
	-- Get our input element.
	local menuController = tes3.worldController.menuController
	local inputFocus = menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Move cursor to the start.
	inputFocus.rawText = inputFocus.rawText:gsub("|", "") .. "|"
	inputFocus:getTopLevelMenu():updateLayout()
end
event.register("keyDown", onKeyDownEnd, { filter = tes3.scanCode["end"] })

--- @class keySubstitution
--- @field pattern string
--- @field repl string

--- @type table<number, keySubstitution>
local keySubstitutions = {
	[tes3.scanCode.backspace] = { pattern = "(%w*[%W]*)|", repl = "|" },
	[tes3.scanCode.delete] = { pattern = "|(%w*[%W]*)", repl = "|" },
	[tes3.scanCode.keyLeft] = { pattern = "(%w*[%W]*)|", repl = "|%1" },
	[tes3.scanCode.keyRight] = { pattern = "|(%w*[%W]*)", repl = "%1|" },
}

--- Generic handler to reposition the cursor to previous/next words.
--- @param e keyDownEventData
local function onKeyDownSubstitute(e)
	if (not e.isControlDown or e.isShiftDown or e.isAltDown or e.isSuperDown) then
		return
	end

	local substitution = keySubstitutions[e.keyCode]

	-- Get our input element.
	local menuController = tes3.worldController.menuController
	local inputFocus = menuController.inputController.textInputFocus
	if (not inputFocus or not inputFocus.visible) then
		return
	end

	-- Make sure the buffer gets cleared so no text makes it to the focused element.
	menuController.inputController:flushBufferedTextEvents()

	-- Move cursor to the start.
	inputFocus.rawText = inputFocus.rawText:gsub(substitution.pattern, substitution.repl)
	inputFocus:getTopLevelMenu():updateLayout()
end
event.register("keyDown", onKeyDownSubstitute, { filter = tes3.scanCode.backspace })
event.register("keyDown", onKeyDownSubstitute, { filter = tes3.scanCode.delete })
event.register("keyDown", onKeyDownSubstitute, { filter = tes3.scanCode.keyLeft })
event.register("keyDown", onKeyDownSubstitute, { filter = tes3.scanCode.keyRight })
