local interop = require("Chromawind.interop")

local module = {}

module.name = "default"
module.disabled = false

function module.clearKeyboardData()
	local data = module.keyboardData
	for r = 1, 6 do
		local row = data[r]
		for c = 1, 22 do
			row[c] = 0
		end
	end
end

function module.resetKeyboardData()
	module.clearKeyboardData()

	-- Setup keybinds.
end

-- Initialize keyboard data.
module.keyboardData = table.new(6, 0)
for r = 1, 6 do
	module.keyboardData[r] = table.new(22, 0)
end
module.clearKeyboardData()

local lastUpdateTime = 0
local throttle = 1
local dataUpdated = false

local function getHopScaled(lower, higher, value)
	if (value >= higher) then
		return 1.0
	elseif (value <= lower) then
		return 0.0
	else
		return math.remap(value, lower, higher, 0.0, 1.0)
	end
end

local getColor = interop.razerSDK.color

local cachedData = {
	health = {
		value = 0,
		onUpdate = function(value)
			value = math.clamp(value, 0.0, 1.0)
			module.keyboardData[1][4] = getColor(getHopScaled(0.00, 0.25, value), 0.0, 0.0)
			module.keyboardData[1][5] = getColor(getHopScaled(0.25, 0.50, value), 0.0, 0.0)
			module.keyboardData[1][6] = getColor(getHopScaled(0.50, 0.75, value), 0.0, 0.0)
			module.keyboardData[1][7] = getColor(getHopScaled(0.75, 1.00, value), 0.0, 0.0)
			-- mwse.log("health: <%x, %x, %x, %x>", module.keyboardData[1][4], module.keyboardData[1][5], module.keyboardData[1][6], module.keyboardData[1][7])
		end,
	},
	magicka = {
		value = 0,
		onUpdate = function(value)
			value = math.clamp(value, 0.0, 1.0)
			module.keyboardData[1][8] = getColor(0.0, 0.0, getHopScaled(0.00, 0.25, value))
			module.keyboardData[1][9] = getColor(0.0, 0.0, getHopScaled(0.25, 0.50, value))
			module.keyboardData[1][10] = getColor(0.0, 0.0, getHopScaled(0.50, 0.75, value))
			module.keyboardData[1][11] = getColor(0.0, 0.0, getHopScaled(0.75, 1.00, value))
			-- mwse.log("magicka: <%x, %x, %x, %x>", module.keyboardData[1][8], module.keyboardData[1][9], module.keyboardData[1][10], module.keyboardData[1][11])
		end,
	},
	fatigue = {
		value = 0,
		onUpdate = function(value)
			value = math.clamp(value, 0.0, 1.0)
			module.keyboardData[1][12] = getColor(0.0, getHopScaled(0.00, 0.25, value), 0.0)
			module.keyboardData[1][13] = getColor(0.0, getHopScaled(0.25, 0.50, value), 0.0)
			module.keyboardData[1][14] = getColor(0.0, getHopScaled(0.50, 0.75, value), 0.0)
			module.keyboardData[1][15] = getColor(0.0, getHopScaled(0.75, 1.00, value), 0.0)
			-- mwse.log("fatigue: <%x, %x, %x, %x>", module.keyboardData[1][12], module.keyboardData[1][13], module.keyboardData[1][14], module.keyboardData[1][15])
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
		interop.razerInstance:createKeyboardEffect("CHROMA_CUSTOM", module.keyboardData)
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