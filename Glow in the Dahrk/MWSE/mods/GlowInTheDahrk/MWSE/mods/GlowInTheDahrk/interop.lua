
local config = require("GlowInTheDahrk.config")

local interop = {}

-- The test of base tes3object types that support switch nodes.
-- Theoretically we could support any object type here, but filtering helps optimize.
local supportedObjectTypes = {
	[tes3.objectType.activator] = true,
	[tes3.objectType.static] = true,
}

-- A dictionary of each weather, showing if they are treated as bright.
-- Bright weathers will make it so interior windows are lit.
local brightWeathers = {
	[tes3.weather.clear] = true,
	[tes3.weather.cloudy] = true,
	[tes3.weather.foggy] = false,
	[tes3.weather.overcast] = false,
	[tes3.weather.rain] = false,
	[tes3.weather.thunder] = false,
	[tes3.weather.ash] = false,
	[tes3.weather.blight] = false,
	[tes3.weather.snow] = true,
	[tes3.weather.blizzard] = false,
}

function interop.isCurrentWeatherBright()
	-- Certain weathers are always considered dark.
	local currentWeather = tes3.getCurrentWeather()
	if (not currentWeather) then
		return true
	end

	return brightWeathers[currentWeather.index]
end

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
