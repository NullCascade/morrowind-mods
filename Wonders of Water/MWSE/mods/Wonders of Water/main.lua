
local config = require("Wonders of Water.config")
local interop = require("Wonders of Water.interop")

local state = nil

local function onCalcSunDamage(e)
	if (state and state.depthFactor and config.features.sunDamage) then
		e.damage = e.damage * state.depthFactor
	end
end
event.register(tes3.event.calcSunDamageScalar, onCalcSunDamage)

local function onSimulate()
	if (not config.enabled) then
		return
	end

	-- Do we have water?
	local waterLevel = tes3.player.cell.waterLevel
	if (waterLevel == nil) then
		return
	end

	-- Get the info for the current weather.
	state = interop.calculateCurrentWaterState()
	if (state == nil) then
		return
	end

	local distantLand = mge.distantLandRenderConfig
	local weatherController = tes3.worldController.weatherController

	if (config.features.waterCaustics) then
		distantLand.waterCaustics = interop.defaultValues.waterCaustics * state.caustics
	end

	if (config.features.waterWaves) then
		distantLand.waterWaveHeight = interop.defaultValues.waterWaveHeight * state.waveHeight
	end

	-- Handle underwater values.
	if (config.features.waterClarity and state.playerDepth > 0) then
		state.nightEyeFactor = tes3.mobilePlayer.visionBonus * 10
		state.weatherFactor = state.clarity
		state.visionFactor = math.max(1.0 + state.nightEyeFactor - state.depthFactor, 0.1)
		distantLand.belowWaterFogStart = interop.defaultValues.belowWaterFogStart * state.visionFactor
		distantLand.belowWaterFogEnd = interop.defaultValues.belowWaterFogEnd * state.visionFactor
		weatherController.underwaterColor = interop.defaultValues.underwaterColor * (1.0 - state.depthFactor)
		-- weatherController.underwaterColorWeight = math.clamp(defaultUnderwaterColorWeight + state.depthFactor, 0.0, 1.0)
		-- tes3.messageBox(string.format("NightEye: %.2f; Depth Factor: %.2f; Weather Factor: %2.f; Vision: %.2f", state.nightEyeFactor, state.depthFactor, state.weatherFactor, state.visionFactor))
	end
end
event.register(tes3.event.simulate, onSimulate)

local function onInitialized()
	-- Fill out the default values we want to build off of.
	interop.defaultValues.belowWaterFogStart = mge.distantLandRenderConfig.belowWaterFogStart
	interop.defaultValues.belowWaterFogEnd = mge.distantLandRenderConfig.belowWaterFogEnd
	interop.defaultValues.underwaterColor = tes3.worldController.weatherController.underwaterColor:copy()
	interop.defaultValues.underwaterColorWeight = tes3.worldController.weatherController.underwaterColorWeight
	interop.defaultValues.waterCaustics = mge.distantLandRenderConfig.waterCaustics
	interop.defaultValues.waterWaveHeight = mge.distantLandRenderConfig.waterWaveHeight
end
event.register(tes3.event.initialized, onInitialized)

-- Offload MCM logic to a separate file.
dofile("Wonders of Water.mcm")
