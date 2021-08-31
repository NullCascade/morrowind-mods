local config = require("GlowInTheDahrk.config")

local interop = {}

interop.enabled = true

local debug = require("GlowInTheDahrk.debug")
debug.interop = interop

--
-- Object support check. Lets us know if a given object cares about GitD.
--

-- The test of base tes3object types that support switch nodes.
-- Theoretically we could support any object type here, but filtering helps optimize.
local supportedObjectTypes = {
	[tes3.objectType.activator] = true,
	[tes3.objectType.static] = true,
}

--- Information about a mesh.
--- @class table.GitD.meshData
--- @field switchChildIndex number The asdf

--- @type table<string, table.GitD.meshData>
local meshData = {}
debug.meshData = meshData

--- Creates data for a given mesh.
---
--- **This should not be called without knowing what you are doing.**
--- @param mesh string Path to the mesh. Must not be prefixed with meshes\\
--- @return table.GitD.meshData data An empty table to provide mesh data for.
function interop.createMeshData(mesh)
	local mesh = mesh:lower()

	local hit = meshData[mesh]
	if (hit) then
		return hit
	end

	meshData[mesh] = {}
	return meshData[mesh]
end

function interop.checkSupport(obj)
	if (not obj) then
		return false
	end

	-- Get basic info.
	local object = obj.baseObject
	local mesh = object.mesh
	if (not mesh) then
		return false
	end
	mesh = mesh:lower()

	-- Object type support check.
	if (not supportedObjectTypes[object.objectType]) then
		-- We don't want to cache thie result, as a valid object type may want to try to use the same mesh.
		return false
	end

	-- Was this object already checked?
	local cacheHit = meshData[mesh]
	return cacheHit ~= nil, cacheHit
end

--
-- Specific regional or weather data to care about.
--

-- The brightness associated with each weather type.
local weatherBrightness = {
	[tes3.weather.clear] = 1.0,
	[tes3.weather.cloudy] = 0.9,
	[tes3.weather.foggy] = 0.5,
	[tes3.weather.overcast] = 0.6,
	[tes3.weather.rain] = 0.4,
	[tes3.weather.thunder] = 0.3,
	[tes3.weather.ash] = 0.5,
	[tes3.weather.blight] = 0.5,
	[tes3.weather.snow] = 0.7,
	[tes3.weather.blizzard] = 0.6,
}

function interop.getCurrentWeatherBrightness()
	local currentWeather = tes3.getCurrentWeather()
	if (not currentWeather) then
		return 1.0
	end
	return weatherBrightness[currentWeather.index]
end

function interop.getSunHours()
	-- Base data.
	local weatherController = tes3.worldController.weatherController

	-- Figure out when our important sunrise times are.
	local sunriseStart = weatherController.sunriseHour - weatherController.sunPreSunriseTime
	local sunriseTotalDuration = weatherController.sunPostSunriseTime + weatherController.sunriseDuration +
	                             weatherController.sunPreSunriseTime
	local sunriseMidPoint = sunriseStart + (sunriseTotalDuration / 2)
	local sunriseStop = sunriseStart + sunriseTotalDuration

	-- Figure out when our important sunset times are.
	local sunsetStart = weatherController.sunsetHour - weatherController.sunPreSunsetTime
	local sunsetTotalDuration = weatherController.sunPostSunsetTime + weatherController.sunsetDuration +
	                            weatherController.sunPreSunsetTime
	local sunsetMidPoint = sunsetStart + (sunsetTotalDuration / 2)
	local sunsetStop = sunsetStart + sunsetTotalDuration

	return sunriseStart, sunriseMidPoint, sunriseStop, sunsetStart, sunsetMidPoint, sunsetStop
end

function interop.calculateRegionSunColor(region)
	-- Base data.
	local worldController = tes3.worldController
	local weatherController = worldController.weatherController
	local gameHour = worldController.hour.value

	-- Figure out when our important times are.
	local sunriseStart, sunriseMidPoint, sunriseStop, sunsetStart, sunsetMidPoint, sunsetStop = interop.getSunHours()
	local sunriseTotalDuration = sunriseStop - sunriseStart
	local sunsetTotalDuration = sunsetStop - sunsetStart

	-- Figure out weather information.
	local weather = region.weather
	local nextWeather = nil
	local weatherTransitionScalar = 0.0
	if (weatherController.lastActiveRegion == region) then
		nextWeather = weatherController.nextWeather
		weatherTransitionScalar = weatherController.transitionScalar
	end

	-- Figure out what our colors are.
	local currentWeatherColor = nil
	local nextWeatherColor = nil
	if (gameHour < sunriseStart or gameHour > sunsetStop) then
		-- Night time
		currentWeatherColor = weather.sunNightColor
		nextWeatherColor = nextWeather and nextWeather.sunNightColor
	elseif (gameHour >= sunsetMidPoint) then
		-- Transition from sunset to night
		local timeTransitionScalar = (gameHour - sunsetMidPoint) / (sunsetTotalDuration / 2)
		currentWeatherColor = weather.sunSunsetColor:lerp(weather.sunNightColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunSunsetColor:lerp(nextWeather.sunNightColor, timeTransitionScalar)
	elseif (gameHour >= sunsetStart) then
		-- Transition from day to sunset
		local timeTransitionScalar = (gameHour - sunsetStart) / (sunsetTotalDuration / 2)
		currentWeatherColor = weather.sunDayColor:lerp(weather.sunSunsetColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunDayColor:lerp(nextWeather.sunSunsetColor, timeTransitionScalar)
	elseif (gameHour >= sunriseStop) then
		-- Day time
		currentWeatherColor = weather.sunDayColor
		nextWeatherColor = nextWeather and nextWeather.sunDayColor
	elseif (gameHour >= sunriseMidPoint) then
		-- Transition from sunrise to day
		local timeTransitionScalar = (gameHour - sunriseMidPoint) / (sunriseTotalDuration / 2)
		currentWeatherColor = weather.sunSunriseColor:lerp(weather.sunDayColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunSunriseColor:lerp(nextWeather.sunDayColor, timeTransitionScalar)
	elseif (gameHour >= sunriseStart) then
		-- Transition from night to sunrise
		local timeTransitionScalar = (gameHour - sunriseStart) / (sunriseTotalDuration / 2)
		currentWeatherColor = weather.sunNightColor:lerp(weather.sunSunriseColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunNightColor:lerp(nextWeather.sunSunriseColor, timeTransitionScalar)
	end

	-- Return the lerped value between current and next weather.
	if (nextWeather) then
		return currentWeatherColor:lerp(nextWeatherColor, weatherTransitionScalar):toColor()
	else
		return currentWeatherColor:toColor()
	end
end

--
-- Management of lights to add to interior windows.
--

local defaultLight = nil

function interop.getDefaultLight()
	-- Lazy-create light if needed.
	if (defaultLight == nil) then
		defaultLight = niPointLight.new()
		-- light.name = "GitD Standard Interior Light"
		defaultLight.diffuse.r = 1.0
		defaultLight.diffuse.g = 1.0
		defaultLight.diffuse.b = 1.0
		defaultLight:setRadius(200.0)
	end

	return defaultLight
end

return interop
