local config = require("GlowInTheDahrk.config")

local interop = {}

interop.enabled = true

--
-- Object support check. Lets us know if a given object cares about GitD.
--

-- The test of base tes3object types that support switch nodes.
-- Theoretically we could support any object type here, but filtering helps optimize.
local supportedObjectTypes = {
	[tes3.objectType.activator] = true,
	[tes3.objectType.static] = true,
}

local objectSupportCache = {}
function interop.checkSupport(obj)
	if (not obj) then
		return false
	end

	-- Get basic info.
	local object = obj.baseObject
	-- local baseObjectID = baseObject.id:lower()
	local mesh = object.mesh
	if (not mesh) then
		return false
	end
	mesh = mesh:lower()

	-- Object type support check.
	if (not supportedObjectTypes[object.objectType]) then
		objectSupportCache[object] = false
		return false
	end

	-- Was this object already checked?
	local cacheHit = objectSupportCache[object]
	if (cacheHit ~= nil) then
		return cacheHit
	end

	-- Get the object's scene graph object.
	local sceneNode = object.sceneNode
	if (not sceneNode) then
		objectSupportCache[object] = false
		return false
	end

	-- Get the first child node.
	local dayNightSwitchNode = (#sceneNode.children > 0) and sceneNode.children[1] or nil

	-- Make sure the node has the name we care about.
	if (not dayNightSwitchNode or dayNightSwitchNode.name ~= "NightDaySwitch") then
		objectSupportCache[object] = false
		return false
	end

	-- All checks passed.
	objectSupportCache[object] = true
	return true
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

function interop.getDawnDuskHours()
	-- Base data.
	local worldController = tes3.worldController
	local weatherController = worldController.weatherController
	local gameHour = worldController.hour.value

	-- Figure out when our important sunrise times are.
	local sunriseStartTime = weatherController.sunriseHour - weatherController.skyPreSunriseTime
	local sunriseTotalDuration = weatherController.skyPostSunriseTime + weatherController.sunriseDuration +
	                             weatherController.skyPreSunriseTime
	local sunriseMidPoint = sunriseStartTime + (sunriseTotalDuration / 2)
	local sunriseStopTime = sunriseStartTime + sunriseTotalDuration

	-- Figure out when our important sunset times are.
	local sunsetStartTime = weatherController.sunsetHour - weatherController.skyPreSunsetTime
	local sunsetTotalDuration = weatherController.skyPostSunsetTime + weatherController.sunsetDuration +
	                            weatherController.skyPreSunsetTime
	local sunsetMidPoint = sunsetStartTime + (sunsetTotalDuration / 2)
	local sunsetStopTime = sunsetStartTime + sunsetTotalDuration

	return sunriseStartTime, sunriseStopTime, sunsetStartTime, sunsetStopTime
end

function interop.calculateRegionSunColor(region)
	-- Base data.
	local worldController = tes3.worldController
	local weatherController = worldController.weatherController
	local gameHour = worldController.hour.value

	-- Figure out when our important sunrise times are.
	local sunriseStartTime = weatherController.sunriseHour - weatherController.skyPreSunriseTime
	local sunriseTotalDuration = weatherController.skyPostSunriseTime + weatherController.sunriseDuration +
	                             weatherController.skyPreSunriseTime
	local sunriseMidPoint = sunriseStartTime + (sunriseTotalDuration / 2)
	local sunriseStopTime = sunriseStartTime + sunriseTotalDuration

	-- Figure out when our important sunset times are.
	local sunsetStartTime = weatherController.sunsetHour - weatherController.skyPreSunsetTime
	local sunsetTotalDuration = weatherController.skyPostSunsetTime + weatherController.sunsetDuration +
	                            weatherController.skyPreSunsetTime
	local sunsetMidPoint = sunsetStartTime + (sunsetTotalDuration / 2)
	local sunsetStopTime = sunsetStartTime + sunsetTotalDuration

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
	if (gameHour < sunriseStartTime or gameHour > sunsetStopTime) then
		-- Night time
		currentWeatherColor = weather.sunNightColor
		nextWeatherColor = nextWeather and nextWeather.sunNightColor
	elseif (gameHour >= sunsetMidPoint) then
		-- Transition from sunset to night
		local timeTransitionScalar = (gameHour - sunsetMidPoint) / (sunsetTotalDuration / 2)
		currentWeatherColor = weather.sunSunsetColor:lerp(weather.sunNightColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunSunsetColor:lerp(nextWeather.sunNightColor, timeTransitionScalar)
	elseif (gameHour >= sunsetStartTime) then
		-- Transition from day to sunset
		local timeTransitionScalar = (gameHour - sunsetStartTime) / (sunsetTotalDuration / 2)
		currentWeatherColor = weather.sunDayColor:lerp(weather.sunSunsetColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunDayColor:lerp(nextWeather.sunSunsetColor, timeTransitionScalar)
	elseif (gameHour >= sunriseStopTime) then
		-- Day time
		currentWeatherColor = weather.sunDayColor
		nextWeatherColor = nextWeather and nextWeather.sunDayColor
	elseif (gameHour >= sunriseMidPoint) then
		-- Transition from sunrise to day
		local timeTransitionScalar = (gameHour - sunriseMidPoint) / (sunriseTotalDuration / 2)
		currentWeatherColor = weather.sunSunriseColor:lerp(weather.sunDayColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunSunriseColor:lerp(nextWeather.sunDayColor, timeTransitionScalar)
	elseif (gameHour >= sunriseStartTime) then
		-- Transition from night to sunrise
		local timeTransitionScalar = (gameHour - sunriseStartTime) / (sunriseTotalDuration / 2)
		currentWeatherColor = weather.sunNightColor:lerp(weather.sunSunriseColor, timeTransitionScalar)
		nextWeatherColor = nextWeather and nextWeather.sunNightColor:lerp(nextWeather.sunSunriseColor, timeTransitionScalar)
	end

	-- Return the lerped value between current and next weather.
	if (nextWeather) then
		return currentWeatherColor:lerp(nextWeatherColor, weatherTransitionScalar)
	else
		return currentWeatherColor
	end
end

--
-- Management of lights to add to interior windows.
--
-- Note that meshLoaded and the .mesh properties may have different prefixes.
--

local customLights = {}

function interop.setLightForMesh(mesh, light)
	customLights[mesh:lower()] = light
end

function interop.getLightForMesh(mesh)
	-- Look for custom light.
	local light = customLights[mesh:lower()]
	if (light ~= nil) then
		return light:clone()
	end

	-- Otherwise make a new light.
	light = niPointLight.new()
	-- light.name = "GitD Standard Interior Light"
	light.diffuse.r = 1
	light.diffuse.g = 1
	light.diffuse.b = 1
	light:setRadius(200)
	return light
end

return interop
