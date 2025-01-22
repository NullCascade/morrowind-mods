local config = require("Wonders of Water.config")

local interop = {}

interop.defaultValues = {}

-- Create a map of weather indexes to names.
interop.weatherIndexMap = {}
for k, v in pairs(tes3.weather) do
	interop.weatherIndexMap[v] = k
end

--- @param weather tes3weather?
function interop.getConfigForWeather(weather)
	if (weather == nil) then
		return
	end

	local name = interop.weatherIndexMap[weather.index]
	if (name == nil) then
		return
	end

	return config.weathers[name]
end

function interop.calculateCurrentWaterState()
	local state = {}

	if (tes3.player == nil) then
		return nil
	end

	state.cell = tes3.player.cell
	if (state.cell == nil) then
		return nil
	end

	state.waterLevel = state.cell.waterLevel
	if (state.waterLevel == nil) then
		return nil
	end

	state.playerHeadPosition = tes3.mobilePlayer.position + tes3vector3.new(0, 0, tes3.mobilePlayer.height)
	state.playerDepth = (state.playerHeadPosition.z - state.waterLevel) * -1
	if (state.playerDepth > 0) then
		state.depthFactor = math.clamp(state.playerDepth / 1500, 0.0, 1.0)
	end

	if (state.cell.isOrBehavesAsExterior) then
		local weatherController = tes3.worldController.weatherController

		local currentConfig = interop.getConfigForWeather(weatherController.currentWeather) --- @type unknown
		local nextConfig = interop.getConfigForWeather(weatherController.nextWeather)
		if (nextConfig) then
			local weatherTransitionScalar = weatherController.transitionScalar
			state.caustics = math.lerp(currentConfig.caustics or 1.0, nextConfig.caustics or 1.0, weatherTransitionScalar)
			state.clarity = math.lerp(currentConfig.clarity or 1.0, nextConfig.clarity or 1.0, weatherTransitionScalar)
			state.waveHeight = math.lerp(currentConfig.waveHeight or 1.0, nextConfig.waveHeight or 1.0, weatherTransitionScalar)
		else
			state.caustics = currentConfig.caustics or 1.0
			state.clarity = currentConfig.clarity or 1.0
			state.waveHeight = currentConfig.waveHeight or 1.0
		end
	else
		state.caustics = 1.0
		state.clarity = 1.0
		state.waveHeight = 0.0
	end

	return state
end

function interop.resetValues()
	local distantLand = mge.distantLandRenderConfig
	distantLand.belowWaterFogEnd = interop.defaultValues.belowWaterFogEnd
	distantLand.belowWaterFogStart = interop.defaultValues.belowWaterFogStart
	distantLand.waterCaustics = interop.defaultValues.waterCaustics
	distantLand.waterWaveHeight = interop.defaultValues.waterWaveHeight

	local weatherController = tes3.worldController.weatherController
	weatherController.underwaterColor = interop.defaultValues.underwaterColor
end

return interop
