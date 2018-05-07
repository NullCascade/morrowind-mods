
--[[
	Mod Initialization: Expeditious Exit
	Author: NullCascade

	This mod is for people who seem to have issues crashing or losing mouse control
	on exit. By hijacking the exit buttons, this mod will force the game to exit.

	Doing it this way isn't wonderful! In a perfect world we wouldn't do it this
	way, but if it helps you, great.
]]--

-- The event we register if we want to just immediately close with no confirmation.
local function checkImmediateClose(e)
    if (e.property == tes3.uiProperty.mouseClick and e.block.name == "MenuOptions_Exit_container") then
		print("[nc-exit] Forcing exit!")
        os.exit()
    end
end

-- Callback used when confirming exit
local function checkConfirmedCloseCallback(e)
	if (e.button == 0) then
		print("[nc-exit] Forcing exit after confirmation!")
		os.exit()
	end
end

-- The event we register if we want to still force-close, but want a confirmation
-- message box first.
local function checkConfirmedClose(e)
	if (e.property == tes3.uiProperty.mouseClick and e.block.name == "MenuOptions_Exit_container") then
		-- Respect languages or whatever by reading the text from GMSTs.
		tes3.messageBox({
			message = tes3.getGMST(612).value,
			buttons = { tes3.getGMST(68).value, tes3.getGMST(69).value },
			callback = checkConfirmedCloseCallback
		})
		return false
    end
end

-- Wait to register events until after initialization so we can read GMSTs.
local function initialize()
	-- Load the config to see if we care about message boxes.
	local config = json.loadfile("nc_exit_config")

	-- Set our event handler accordingly.
	if (config and config.showMessageBox == true) then
		event.register("uiPreEvent", checkConfirmedClose)
	else
		event.register("uiPreEvent", checkImmediateClose)
	end

	-- Show initialization event in the log.
	print("[nc-exit] Mod initialized with configuration:")
	print(json.encode(config, { indent = true }))
end
event.register("initialized", initialize)
