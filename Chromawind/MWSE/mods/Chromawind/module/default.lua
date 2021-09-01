local interop = require("Chromawind.interop")

local getColor = interop.razerSDK.color
local getColorWithEffect = interop.razerSDK.colorEffect
local defaultColor = getColor(0.1, 0.1, 0.1)

local module = {}

module.name = "default"
module.disabled = false

function module.clearKeyboardKeyData()
	local key = module.keyboardData.key
	for r = 1, 6 do
		local row = key[r]
		for c = 1, 22 do
			row[c] = 0
		end
	end
end

function module.clearKeyboardColorData()
	local color = module.keyboardData.color
	for r = 1, 6 do
		local row = color[r]
		for c = 1, 22 do
			row[c] = defaultColor
		end
	end
end

function module.clearKeyboardData()
	module.clearKeyboardKeyData()
	module.clearKeyboardColorData()
end

function module.resetKeyboardData()
	module.clearKeyboardData()

	-- Setup keybinds.
end

-- Initialize keyboard data.
module.keyboardData = {}
module.keyboardData.key = {} --table.new(6, 0)
for r = 1, 6 do
	module.keyboardData.key[r] = {} --table.new(22, 0)
end
module.keyboardData.color = {} --table.new(6, 0)
for r = 1, 6 do
	module.keyboardData.color[r] = {} --table.new(22, 0)
end
module.clearKeyboardData()

local lastUpdateTime = 0
local throttle = 1
local dataUpdated = false

local function getHopScaled(lower, higher, value)
	if (value > higher) then
		return 1.0
	elseif (value < lower) then
		return 0.0
	else
		return math.remap(value, lower, higher, 0.0, 1.0)
	end
end

local cachedData = {
	health = {
		value = 0,
		onUpdate = function(value)
			value = math.clamp(value, 0.0, 1.0)
			local keys = module.keyboardData.key[1]
			keys[4] = getColorWithEffect(getHopScaled(0.00, 0.25, value), 0.0, 0.0)
			keys[5] = getColorWithEffect(getHopScaled(0.25, 0.50, value), 0.0, 0.0)
			keys[6] = getColorWithEffect(getHopScaled(0.50, 0.75, value), 0.0, 0.0)
			keys[7] = getColorWithEffect(getHopScaled(0.75, 1.00, value), 0.0, 0.0)
			-- mwse.log("health: <%x, %x, %x, %x>", keys[4], keys[5], keys[6], keys[7])
		end,
	},
	magicka = {
		value = 0,
		onUpdate = function(value)
			value = math.clamp(value, 0.0, 1.0)
			local keys = module.keyboardData.key[1]
			keys[8] = getColorWithEffect(0.0, 0.0, getHopScaled(0.00, 0.25, value))
			keys[9] = getColorWithEffect(0.0, 0.0, getHopScaled(0.25, 0.50, value))
			keys[10] = getColorWithEffect(0.0, 0.0, getHopScaled(0.50, 0.75, value))
			keys[11] = getColorWithEffect(0.0, 0.0, getHopScaled(0.75, 1.00, value))
			-- mwse.log("magicka: <%x, %x, %x, %x>", keys[8], keys[9], keys[10], keys[11])
		end,
	},
	fatigue = {
		value = 0,
		onUpdate = function(value)
			value = math.clamp(value, 0.0, 1.0)
			local keys = module.keyboardData.key[1]
			keys[12] = getColorWithEffect(0.0, getHopScaled(0.00, 0.25, value), 0.0)
			keys[13] = getColorWithEffect(0.0, getHopScaled(0.25, 0.50, value), 0.0)
			keys[14] = getColorWithEffect(0.0, getHopScaled(0.50, 0.75, value), 0.0)
			keys[15] = getColorWithEffect(0.0, getHopScaled(0.75, 1.00, value), 0.0)
			-- mwse.log("fatigue: <%x, %x, %x, %x>", keys[12], keys[13], keys[14], keys[15])
		end,
	},
}

local function resetCachedData()
	for _, v in pairs(cachedData) do
		v.value = v.defaultValue or 0
		v.onUpdate(v.value)
		dataUpdated = true
	end
end

local function updateCachedData(key, newValue)
	if (cachedData[key].value ~= newValue) then
		local data = cachedData[key]
		data.value = newValue
		data.onUpdate(newValue)
		dataUpdated = true
	end
end

function module.onEnterFrame(dt)
	if (module.disabled) then
		return
	end

	-- Throttle updating to 60 FPS.
	local now = os.clock()
	if (now - lastUpdateTime < throttle) then
		return
	end

	-- Do we have a player?
	if (tes3.mobilePlayer) then
		-- Update basic statistics.
		updateCachedData("health", tes3.mobilePlayer.health.normalized)
		updateCachedData("magicka", tes3.mobilePlayer.magicka.normalized)
		updateCachedData("fatigue", tes3.mobilePlayer.fatigue.normalized)
	end

	-- Only update when we need to.
	if (dataUpdated) then
		interop.razerInstance:createKeyboardEffect("CHROMA_CUSTOM_KEY", module.keyboardData)
		lastUpdateTime = now
		dataUpdated = false
	end
end

function module.onStart()

end

function module.onStop()

end

local function onGameLoaded(e)
	module.resetKeyboardData()
	resetCachedData()
end
event.register("loaded", onGameLoaded)

return module