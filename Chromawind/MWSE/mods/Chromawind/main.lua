
-- Initialize interop.
local interop = require("Chromawind.interop")
interop.razerSDK = require("Chromawind.ChromaSDK")
interop.razerInstance = interop.razerSDK.new({
	title = "The Elder Scrolls III - Morrowind",
	description = "Unofficial Chroma SDK support for Morrowind, using mwse-lua and the Chrome SDK's REST API.",
	author = {
		name = "NullCascade",
		contact = "NullCascade@gmail.com",
	},
	device_supported = {
		"keyboard",
		-- "mouse",
		-- "headset",
		-- "mousepad",
		-- "keypad",
		-- "chromalink",
	},
	category = "game",
})

local function assertColor(r, g, b, hex)
	local color = interop.razerSDK.color(r, g, b)
	local colorHex = string.format("%x", color)
	assert(colorHex == hex, string.format("Incorrect hex value for <%.2f, %.2f, %.2f>: %s vs. %s", r, g, b, colorHex, hex))
end

assertColor(1.0, 0.0, 0.0, "ff")
assertColor(0.0, 1.0, 0.0, "ff00")
assertColor(0.0, 0.0, 1.0, "ff0000")
assertColor(0.0, 0.0, 0.0, "0")
assertColor(0.5, 0.5, 0.5, "7f7f7f")
assertColor(1.0, 1.0, 1.0, "ffffff")

-- Initialize empty effect.
interop.effects.none = interop.razerInstance:preCreateKeyboardEffect("CHROMA_NONE")

interop.modules.default = require("Chromawind.module.default")
interop.modules.loading = require("Chromawind.module.loading")
interop.setCurrentModule()

local timeSinceUpdate = 0

--- @param e enterFrameEventData
local function onEnterFrame(e)
	local delta = e.delta

	-- Let the module update.
	local module = interop.getCurrentModule()
	if (module.onEnterFrame) then
		module.onEnterFrame(delta)
	end

	-- Fire off a heartbeat every second. Otherwise Razer will shut us down after 15 seconds.
	timeSinceUpdate = timeSinceUpdate + delta
	if (timeSinceUpdate > 1.0) then
		interop.razerInstance:heartbeat()
		timeSinceUpdate = 0
	end
end
event.register("enterFrame", onEnterFrame)

--- Add quick access to the mod from the console.
--- @param e table
local function onSandboxConsole(e)
	e.sandbox.chroma = interop
end
event.register("UIEXP:sandboxConsole", onSandboxConsole)

event.trigger("chromawind:initialized")
