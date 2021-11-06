--[[
	Mod Initialization: Expeditious Exit
	Author: NullCascade

	This mod is for people who seem to have issues crashing or losing mouse control
	on exit. By hijacking the exit buttons, this mod will force the game to exit.

	Doing it this way isn't wonderful! In a perfect world we wouldn't do it this
	way, but if it helps you, great.
]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20210817) then
	mwse.log("[Expeditious Exit] Build date of %s does not meet minimum build date of 20210817.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/exit/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/exit/", true)) then
		mwse.log("[Expeditious Exit] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Expeditious Exit] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/exit' and restart Morrowind.")
		return
	end
end

local config = require("Expeditious Exit.config")

-- Our close the damn game function, depending on user config.
local function shutItDown()
	if (config.useTaskKill) then
		os.createProcess({ command = [[taskkill /IM "Morrowind.exe" /F]] })
	else
		os.exit()
	end
end

-- Callback used when confirming exit
local function checkConfirmedCloseCallback(e)
	if (e.button == 0) then
		mwse.log("[Expeditious Exit] Forcing exit after confirmation!")
		shutItDown()
	end
end

-- The event we register if we want to still force-close, but want a confirmation
-- message box first.
local function onExitButtonClicked(e)
	if (config.showMenuOnExit) then
		-- Respect languages or whatever by reading the text from GMSTs.
		tes3.messageBox({
			message = tes3.findGMST(tes3.gmst.sMessage2).value,
			buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
			callback = checkConfirmedCloseCallback,
		})
	else
		mwse.log("[Expeditious Exit] Forcing exit!")
		shutItDown()
	end
end

-- When the UI is created, change the exit button's behavior.
local function rebindExitButton(e)
	-- Try to find the options menu exit button.
	local exitButton = e.element:findChild(tes3ui.registerID("MenuOptions_Exit_container"))
	if (exitButton == nil) then
		mwse.log("[Expeditious Exit] Couldn't find exit button UI element!")
		return
	end

	-- Set our new event handler.
	exitButton:register("mouseClick", onExitButtonClicked)
end
event.register("uiCreated", rebindExitButton, { filter = "MenuOptions" })

-- Allow quitting with alt-F4
local function onAltF4(e)
	if (config.allowAltF4 and e.isAltDown) then
		shutItDown()
	end
end
event.register("keyDown", onAltF4, { filter = tes3.scanCode.F4 })

--
-- Handle mod config menu.
--

dofile("Expeditious Exit.mcm")
