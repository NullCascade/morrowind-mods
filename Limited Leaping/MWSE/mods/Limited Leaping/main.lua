
-- The default configuration values.
local defaultConfig = {
	cooldown = 2,
	minimumFatigue = 1,
}

-- Load our config file, and fill in default values for missing elements.
local config = mwse.loadConfig("Limited Leaping")
if (config == nil) then
	config = defaultConfig
else
	for k, v in pairs(defaultConfig) do
		if (config[k] == nil) then
			config[k] = v
		end
	end
end

-- Store faster access to the keyboard state, since it won't get recreated.
local keyboardState = nil

-- Keep track of if jumping is blocked or not.
local jumpBlocked = false

-- Simple function to unblock jumping so that events can set the variable.
local function unblockJumping()
	jumpBlocked = false
end

-- We want to reset the block whenever a game is loaded.
event.register("loaded", unblockJumping)

-- Blocks jumping and starts our timer, if jumping isn't already blocked.
local function blockJumping()
	if (not jumpBlocked and config.cooldown > 0) then
		jumpBlocked = true
		timer.start({
			type = timer.simulate,
			duration = config.cooldown,
			callback = unblockJumping,
		})
	end
end

-- When the jump key is pressed, unpress it if jumping is blocked or we're out of fatigue.
local function onKeyEvent(e)
	if (jumpBlocked or tes3.mobilePlayer.fatigue.current < config.minimumFatigue) then
		keyboardState[e.keyCode + 1] = 0
	else
		blockJumping()
	end
end

-- When we initialize, figure out what the jump key is and bind the key event to it.
local function onInitialized()
	keyboardState = tes3.worldController.inputController.keyboardState
	event.register("keyDown", onKeyEvent, { filter = tes3.getInputBinding(tes3.keybind.jump).code })
end
event.register("initialized", onInitialized)

-- Set up MCM.
local modConfig = require("Limited Leaping.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Limited Leaping", modConfig)
end
event.register("modConfigReady", registerModConfig)
