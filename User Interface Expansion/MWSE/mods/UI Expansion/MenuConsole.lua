
local GUI_ID_MenuConsole = tes3ui.registerID("MenuConsole")
local GUI_ID_MenuConsole_text_input = tes3ui.registerID("MenuConsole_text_input")
local GUI_ID_MenuConsole_scroll_pane = tes3ui.registerID("MenuConsole_scroll_pane")

local GUI_ID_UIEXP_ConsoleInputBox = tes3ui.registerID("UIEXP:ConsoleInputBox")

local common = require("UI Expansion.common")

local luaMode = false

local currentHistoryIndex = 1
local previousEntries = { { text = "", lua = false } }

local function addEntry(text)
	table.insert(previousEntries, { text = text, lua = luaMode })
end

local function onSubmitCommand(e)
	local menuConsole = tes3ui.findMenu(GUI_ID_MenuConsole)
	local inputBox = menuConsole:findChild(GUI_ID_UIEXP_ConsoleInputBox)
	local text = inputBox.text
	inputBox.text = ""

	if (luaMode) then
		tes3ui.logToConsole(text, true)
		local f, message = loadstring(text)
		if (f) then
			local status, errorOrResult = pcall(f)
			if (status) then
				if (errorOrResult ~= nil) then
					tes3ui.logToConsole(string.format("> %s", errorOrResult))
				end
			else
				tes3ui.logToConsole(errorOrResult)
			end
		else
			tes3ui.logToConsole(message)
		end
	else
		local vanillaInputText = menuConsole:findChild(GUI_ID_MenuConsole_text_input)
		vanillaInputText.text = text
		menuConsole:triggerEvent("keyEnter")
	end

	local vanillaInputText = menuConsole:findChild(GUI_ID_MenuConsole_text_input)
	if (vanillaInputText) then
		vanillaInputText.visible = false
	end
	tes3ui.acquireTextInput(inputBox)
	
	table.insert(previousEntries, { text = text, lua = luaMode })
end

local function onMenuConsoleActivated(e)
	mwse.log("Activated %s (%s)", e.id, e.newlyCreated)
	if (not e.newlyCreated) then
		tes3ui.acquireTextInput(e.element:findChild(GUI_ID_UIEXP_ConsoleInputBox))
		return
	end
	
	local menuConsole = e.element
	local mainPane = menuConsole:findChild(GUI_ID_MenuConsole_scroll_pane).parent
	mainPane.borderBottom = 0
	
	-- Disable normal input method.
	local vanillaInputText = menuConsole:findChild(GUI_ID_MenuConsole_text_input)
	vanillaInputText.visible = false

	-- Create a new input block for our new controls..
	local inputBlock = mainPane:createBlock({})
	inputBlock.flowDirection = "left_to_right"
	inputBlock.widthProportional = 1.0
	inputBlock.autoHeight = true
	inputBlock.borderTop = 4
	inputBlock.childAlignY = 0.5

	-- Create a input box.
	local border = inputBlock:createThinBorder({})
	border.autoWidth = true
	border.autoHeight = true
	border.widthProportional = 1.0

	-- Create the search input itself.
	local input = border:createTextInput({ id = tes3ui.registerID("UIEXP:ConsoleInputBox") })
	input.borderLeft = 5
	input.borderRight = 5
	input.borderTop = 2
	input.borderBottom = 4
	input.widget.eraseOnFirstKey = true
	input:register("keyEnter", onSubmitCommand)

	-- Create toggle button.
	local scriptToggleButton = inputBlock:createButton({ text = "mwscript" })
	scriptToggleButton.borderAllSides = 0
	scriptToggleButton.borderLeft = 4
	scriptToggleButton:register("mouseClick", function(e)
		luaMode = not luaMode
		if (luaMode) then
			scriptToggleButton.text = "lua"
		else
			scriptToggleButton.text = "mwscript"
		end
	end)
	input:register("keyPress", function(e)
		local inputController = tes3.worldController.inputController
		local keyboardState = inputController.keyboardState
		for i = 1, #keyboardState do
			if (keyboardState[i] ~= 0) then
				mwse.log("Key down: %d, %d", i, keyboardState[i])
			end
		end
		if (inputController:isKeyDown(15)) then
			-- Prevent alt-tabbing from creating spacing.
			return
		elseif (inputController:isKeyDown(14) and input.text == "") then
			-- Prevent backspacing into nothing.
			return
		elseif (inputController:isKeyDown(200)) then
			-- Pressing up goes to the previous entry in the history.
			currentHistoryIndex = currentHistoryIndex - 1
			if (currentHistoryIndex < 1) then
				currentHistoryIndex = #previousEntries
			end
			input.text = previousEntries[currentHistoryIndex].text
			luaMode = previousEntries[currentHistoryIndex].lua
			if (luaMode) then
				scriptToggleButton.text = "lua"
			else
				scriptToggleButton.text = "mwscript"
			end
			return
		elseif (inputController:isKeyDown(208)) then
			-- Pressing down goes to the next entry in the history.
			currentHistoryIndex = currentHistoryIndex + 1
			if (currentHistoryIndex > #previousEntries) then
				currentHistoryIndex = 1
			end
			input.text = previousEntries[currentHistoryIndex].text
			luaMode = previousEntries[currentHistoryIndex].lua
			if (luaMode) then
				scriptToggleButton.text = "lua"
			else
				scriptToggleButton.text = "mwscript"
			end

			return
		end

		input:forwardEvent(e)
	end)

	-- Make it so clicking on the border focuses the input box.
	input.consumeMouseEvents = false
	border:register("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)

	tes3ui.acquireTextInput(input)
end
event.register("uiActivated", onMenuConsoleActivated, { filter = "MenuConsole" } )
