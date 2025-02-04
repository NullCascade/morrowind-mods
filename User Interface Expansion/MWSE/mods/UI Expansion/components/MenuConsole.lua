local GUI_ID_MenuConsole = tes3ui.registerID("MenuConsole")
local GUI_ID_MenuConsole_text_input = tes3ui.registerID("MenuConsole_text_input")
local GUI_ID_MenuConsole_scroll_pane = tes3ui.registerID("MenuConsole_scroll_pane")

local GUI_ID_UIEXP_ConsoleInputBox = tes3ui.registerID("UIEXP:ConsoleInputBox")

local mwseUICommon = require("mwse.common.ui")
local common = require("UI Expansion.lib.common")
local config = common.config

local currentHistoryIndex = 1
local previousConsoleEntries = config.previousConsoleEntries
if (previousConsoleEntries == nil) then
	previousConsoleEntries = { { text = "", lua = false } }
end

local sandbox = {}

--- Clear the console's output.
local function clearConsole()
	local MenuConsole = tes3ui.findMenu("MenuConsole")
	if (not MenuConsole) then return end
	MenuConsole:findChild("MenuConsole_scroll_pane"):findChild("PartScrollPane_pane"):destroyChildren()
end

--- Initializes the lua sandbox.
local function sandboxInit()
	setmetatable(sandbox, { __index = _G })
	sandbox.print = tes3ui.log
	sandbox.cls = clearConsole
	event.trigger("UIEXP:sandboxConsole", { sandbox = sandbox })
end

--- Runs a given loaded function using the sandbox.
---
--- Also updates the currentRef sandbox variable with the current console reference.
--- @param f function
--- @return ...
local function sandboxScript(f)
	sandbox.currentRef = tes3ui.findMenu(GUI_ID_MenuConsole):getPropertyObject("MenuConsole_current_ref")
	setfenv(f, sandbox)
	return pcall(f)
end

--- Invoked when the command box is submitted.
local function onSubmitCommand()
	local menuConsole = assert(tes3ui.findMenu(GUI_ID_MenuConsole))
	local inputBox = menuConsole:findChild(GUI_ID_UIEXP_ConsoleInputBox)
	local text = inputBox.text
	inputBox.text = ""

	local context = debug.log(menuConsole:findChild("UIEXP:ConsoleModeButton").widget.value)
	local luaMode = (context == "lua")
	if (luaMode) then
		tes3ui.logToConsole(text, true)
	end

	local e = event.trigger("UIEXP:consoleCommand", { command = text, context = context }, { filter = context })
	if (e) then
		text = e.command
	end

	if (not e or not e.block) then
		if (luaMode) then
			-- Break the text into multiple separate lines and run each one independently.
			local lineBrokenText = string.split(string.gsub(text, "\r", ""), "\n")
			for _, line in ipairs(lineBrokenText) do
				-- Try compiling command as an expression first.
				local f, message = loadstring("return " .. line)
				if (not f) then
					f, message = loadstring(line)
				end

				-- Run command and show output in console.
				if (f) then
					local results = { sandboxScript(f) }
					local status = results[1]
					if (status) then
						if (#results > 1) then
							-- Get all of our return values to print, but we have to conver them to strings first.
							local values = {}
							for i = 2, #results do
								values[i - 1] = tostring(results[i])
							end
							tes3ui.log(string.format("> %s", table.concat(values, ", ")))
						end
					else
						tes3ui.log(results[2])
					end
				else
					tes3ui.log(message)
				end
			end
		else
			-- Any of the togglestats reporting outputs will destroy the text input,
			-- which is recreated on the next key input, so send one.
			menuConsole:triggerEvent("keyEnter")

			local vanillaInputText = menuConsole:findChild(GUI_ID_MenuConsole_text_input)
			vanillaInputText.text = text
			menuConsole:triggerEvent("keyEnter")
		end
	end

	local vanillaInputText = menuConsole:findChild(GUI_ID_MenuConsole_text_input)
	if (vanillaInputText) then
		vanillaInputText.visible = false
	end

	-- updateLayout twice, first to layout text, second to update scroll pane
	menuConsole:updateLayout()
	menuConsole:updateLayout()
	tes3ui.acquireTextInput(inputBox)

	-- Save last used console commands to the command history.
	if (text ~= "") then
		local lastEntry = previousConsoleEntries[#previousConsoleEntries]
		if (not lastEntry or lastEntry.text ~= text or lastEntry.lua ~= luaMode) then
			table.insert(previousConsoleEntries, { text = text, lua = luaMode })

			-- Save a selection of the history.
			local savedEntries = {} --- @type uiexpansion.config.consoleEntry[]
			local previousConsoleEntriesCount = #previousConsoleEntries
			for i = math.max(1, previousConsoleEntriesCount - config.consoleHistoryLimit), previousConsoleEntriesCount do
				table.insert(savedEntries, previousConsoleEntries[i])
			end
			savedEntries[1] = { text = "", lua = false }
			config.previousConsoleEntries = savedEntries
			mwse.saveConfig("UI Expansion", config)
		end
	end

	-- Reset the history index.
	currentHistoryIndex = 1

	-- Make sure the original execution doesn't happen.
	return false
end

--- @param e tes3uiEventData
local function onConsoleTextKeyDownBefore(e)
	local element = e.source
	local keyPressed = mwseUICommon.eventCallbackHelper.getKeyPressed(e)
	local menu = element:getTopLevelMenu()
	local key = e.data0

	if (key == 1) then
		-- Pressing up goes to the previous entry in the history.
		currentHistoryIndex = currentHistoryIndex - 1
		if (currentHistoryIndex < 1) then
			currentHistoryIndex = #previousConsoleEntries
		end

		-- Add caret to allow immediate editing.
		local entry = previousConsoleEntries[currentHistoryIndex]
		element.text = entry.text .. "|"

		menu:findChild("UIEXP:ConsoleModeButton").widget.value = entry.lua and "lua" or "mwscript"
		menu:updateLayout()
		return false
	elseif (key == 2) then
		-- Pressing down goes to the next entry in the history.
		currentHistoryIndex = currentHistoryIndex + 1
		if (currentHistoryIndex > #previousConsoleEntries) then
			currentHistoryIndex = 1
		end

		-- Add caret to allow immediate editing.
		local entry = previousConsoleEntries[currentHistoryIndex]
		element.text = entry.text .. "|"

		menu:findChild("UIEXP:ConsoleModeButton").widget.value = entry.lua and "lua" or "mwscript"
		menu:updateLayout()
		return false
	elseif (key == 9) then
		-- Pressing tab toggles the script type.
		menu:findChild("UIEXP:ConsoleModeButton").widget:next()
		menu:updateLayout()
		return false
	end
end

--- @param e tes3uiEventData
local function onMenuConsoleUpdated(e)
	local menuConsole = e.source
	if (menuConsole.visible) then
		return
	end

	local consoleInput = e.source:findChild(GUI_ID_UIEXP_ConsoleInputBox)
	local currentInput = tes3.worldController.menuController.inputController.textInputFocus
	if (currentInput ~= consoleInput) then
		return
	end

	tes3ui.acquireTextInput(nil)
end

--- Create our changes for MenuConsole.
--- @param e uiActivatedEventData
local function onMenuConsoleActivated(e)
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
	local inputBlock = mainPane:createBlock{}
	inputBlock.flowDirection = "left_to_right"
	inputBlock.widthProportional = 1.0
	inputBlock.autoHeight = true
	inputBlock.borderTop = 4
	inputBlock.childAlignY = 0.5

	-- Create the command input.
	local input = inputBlock:createTextInput({ id = "UIEXP:ConsoleInputBox", createBorder = true, autoFocus = true })
	input:registerBefore("keyEnter", onSubmitCommand)
	input:registerBefore("keyPress", onConsoleTextKeyDownBefore)

	-- Create toggle button.
	local scriptToggleButton = inputBlock:createCycleButton({
		id = "UIEXP:ConsoleModeButton",
		options = {
			{ text = "mwscript", value = "mwscript" },
			{ text = "lua", value = "lua" },
		},
		index = 1,
	})
	scriptToggleButton.borderAllSides = 0
	scriptToggleButton.borderLeft = 4
	scriptToggleButton.minWidth = 90
	scriptToggleButton.width = 90
	local toggleText = scriptToggleButton.children[1]
	toggleText.wrapText = true
	toggleText.justifyText = "center"

	-- Make it so hiding the menu hides the input bar.
	menuConsole:registerAfter("update", onMenuConsoleUpdated)

	menuConsole:updateLayout()
end
event.register("uiActivated", onMenuConsoleActivated, { filter = "MenuConsole" })

sandboxInit()
