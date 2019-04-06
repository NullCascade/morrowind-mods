
--[[
	Mod Initialization: Expeditious Exit
	Author: NullCascade

	This mod is for people who seem to have issues crashing or losing mouse control
	on exit. By hijacking the exit buttons, this mod will force the game to exit.

	Doing it this way isn't wonderful! In a perfect world we wouldn't do it this
	way, but if it helps you, great.
]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180726) then
	mwse.log("[Expeditious Exit] Build date of %s does not meet minimum build date of 20180726.", mwse.buildDate)
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

-- Callback used when confirming exit
local function checkConfirmedCloseCallback(e)
	if (e.button == 0) then
		mwse.log("[Expeditious Exit] Forcing exit after confirmation!")
		os.exit()
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
			callback = checkConfirmedCloseCallback
		})
	else
		mwse.log("[Expeditious Exit] Forcing exit!")
		os.exit()
	end
end

-- Load the config to see if we care about message boxes.
local function onInitialized()
	-- Show initialization event in the log.
	mwse.log("[Expeditious Exit] Mod initialized with configuration:")
	mwse.log(json.encode(config, { indent = true }))
end
event.register("initialized", onInitialized)

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

--
-- Handle mod config menu.
--

local function registerModConfig()
	local easyMCM = include("easyMCM.modConfig")
	if (easyMCM) then
		easyMCM.registerMCM(require("Expeditious Exit.mcm"))
	end
end
event.register("modConfigReady", registerModConfig)
