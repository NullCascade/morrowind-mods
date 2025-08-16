local config = require("GlowInTheDahrk.config")

local interop = {}

interop.enabled = true

local debug = require("GlowInTheDahrk.debug")
debug.interop = interop

local cellData = require("GlowInTheDahrk.cellData")
interop.cellData = cellData

--
-- Object support check. Lets us know if a given object cares about GitD.
--

-- The test of base tes3object types that support switch nodes.
-- Theoretically we could support any object type here, but filtering helps optimize.
local supportedObjectTypes = {
	[tes3.objectType.activator] = true,
	[tes3.objectType.static] = true,
}

--- Information about a mesh that GitD controls.
--- @class table.GitD.meshData
--- @field cellData table<string, table.GitD.cellData> Cell data for given cells for this mesh.
--- @field indexInDay number The index to use when swapping to day in interiors.
--- @field indexOff number The index to use to turn the source "off".
--- @field indexOn number The index to use to turn the source "on".
--- @field interiorRayIndex number The index of our GitD node that holds interior sunrays.
--- @field light niLight The base light used by clones.
--- @field litInteriorWindowDefaultValues table<number, niMaterialProperty> A dictionary of indicies that hold default material information.
--- @field litInteriorWindowShapesIndexes number[] A list of indicies that hold lit interior window shapes. We will use this list to update material properties.
--- @field litInteriorWindowShapesOffMaterials table<number, niMaterialProperty> A dictionary of indicies that hold the materials for lit material shapes when off.
--- @field supportsLight boolean The mesh supports a light and GitD will try to attach one.
--- @field switchChildIndex number The index that the nightdayswitch child can be found on.
--- @field unlitInteriorWindowDefaultValues table<number, niMaterialProperty> A dictionary of indicies that hold default material information.
--- @field unlitInteriorWindowShapesIndexes number[] A list of indicies that hold unlit interior window shapes. We will use this list to update material properties.
--- @field valid boolean If true, the mesh data is valid and didn't encounter any errors when loading.

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

	-- Initialize empty data.
	local data = {}
	meshData[mesh] = data

	-- Load cell-specific data.
	data.cellData = {}
	for cell, profiles in pairs(interop.cellData.definitions) do
		local cellData = {}
		for _, profileKey in ipairs(profiles) do
			local profileData = interop.cellData.profiles[profileKey]
			if (profileData) then
				for _, entry in ipairs(profileData) do
					if (string.find(mesh, entry.mesh, entry.init, entry.plain)) then
						for k, v in pairs(entry.data) do
							cellData[k] = v
						end
					end
				end
			end
		end

		if (not table.empty(cellData)) then
			data.cellData[cell] = cellData
		end
	end

	-- Default to an invalid state.
	data.valid = false

	-- Return what we have.
	return data
end

--- comment
--- @param reference tes3reference
--- @return boolean hasSupport Glow in the Dahrk will support this mesh.
--- @return table.GitD.meshData meshData The mesh data that will be used for the object.
function interop.checkSupport(reference)
	if (not reference) then
		return false
	end

	-- Get basic info.
	local object = reference.baseObject
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
	return cacheHit ~= nil and cacheHit.valid, cacheHit
end

function interop.resetConfigurableStateForAllReferences()
	for reference, _ in pairs(interop.trackedReferences) do
		interop.resetConfigurableState(reference)
	end
end

--- @param reference tes3reference
function interop.resetConfigurableState(reference)
	local sceneNode = reference.sceneNode
	if (not sceneNode) then
		return
	end

	local supported, meshData = interop.checkSupport(reference)
	if (not supported or not meshData) then
		return
	end

	local switchNode = sceneNode.children[meshData.switchChildIndex]
	local currentNode = switchNode:getActiveChild()
	local currentIndex = switchNode.switchIndex + 1

	-- Reset for daylight.
	if (currentIndex == meshData.indexInDay) then
		-- Reset rays if needed.
		if (meshData.interiorRayIndex) then
			currentNode.children[meshData.interiorRayIndex].appCulled = not config.addInteriorSunrays
		end

		-- Reset light if needed.
		if (meshData.supportsLight) then
			if (config.addInteriorLights) then
				local cachedLight = meshData.light or interop.getDefaultLight()
				local attachment = reference:getOrCreateAttachedDynamicLight(cachedLight:clone())
				local light = attachment and attachment.light
				local currentRegionSunColor = interop.calculateRegionSunColor(interop.getRegion())
				if (light and currentRegionSunColor) then
					local cachedLight = cachedLight or meshData.light or interop.getDefaultLight()
					local lerpedColor = cachedLight.diffuse * currentRegionSunColor
					light.diffuse = lerpedColor

					-- Fade light in/out at dawn/dusk.
					local sunriseStart, sunriseMidPoint, sunriseStop, sunsetStart, sunsetMidPoint, sunsetStop = interop.getSunHours()
					local currentWeatherBrightness = interop.getCurrentWeatherBrightness()
					local gameHour = tes3.worldController.hour.value
					if (sunriseMidPoint < gameHour and gameHour < sunsetMidPoint) then
						light.dimmer = currentWeatherBrightness
					elseif (sunriseStart <= gameHour and gameHour <= sunriseMidPoint) then
						light.dimmer = currentWeatherBrightness * math.remap(gameHour, sunriseStart, sunriseMidPoint, 0.0, 1.0)
					elseif (sunsetMidPoint <= gameHour and gameHour <= sunsetStop) then
						light.dimmer = currentWeatherBrightness * math.remap(gameHour, sunsetStop, sunsetMidPoint, 0.0, 1.0)
					else
						light.dimmer = 0.0
					end
				end
			else
				reference:deleteDynamicLightAttachment(true)
			end
		end
	end
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
	local sunriseTotalDuration = weatherController.sunPostSunriseTime + weatherController.sunriseDuration + weatherController.sunPreSunriseTime
	local sunriseMidPoint = sunriseStart + (sunriseTotalDuration / 2)
	local sunriseStop = sunriseStart + sunriseTotalDuration

	-- Figure out when our important sunset times are.
	local sunsetStart = weatherController.sunsetHour - weatherController.sunPreSunsetTime
	local sunsetTotalDuration = weatherController.sunPostSunsetTime + weatherController.sunsetDuration + weatherController.sunPreSunsetTime
	local sunsetMidPoint = sunsetStart + (sunsetTotalDuration / 2)
	local sunsetStop = sunsetStart + sunsetTotalDuration

	return sunriseStart, sunriseMidPoint, sunriseStop, sunsetStart, sunsetMidPoint, sunsetStop
end

interop.minimumSunColorLength = 0.4

--- @param region tes3region
--- @return niColor
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

	-- Lerp value between current and next weather.
	local resultVector = currentWeatherColor
	if (nextWeather) then
		resultVector = currentWeatherColor:lerp(nextWeatherColor, weatherTransitionScalar)
	end

	-- Force a minimum brightness.
	if (resultVector:length() < interop.minimumSunColorLength) then
		resultVector = resultVector:normalized() * interop.minimumSunColorLength
	end

	return resultVector:toColor()
end

--
-- Management of lights to add to interior windows.
--

local defaultLight = nil

--- @return niPointLight
function interop.getDefaultLight()
	-- Lazy-create light if needed.
	if (defaultLight == nil) then
		defaultLight = niPointLight.new() --- @type niPointLight
		-- light.name = "GitD Standard Interior Light"
		defaultLight.diffuse.r = 1.0
		defaultLight.diffuse.g = 1.0
		defaultLight.diffuse.b = 1.0
		defaultLight:setRadius(200.0)
	end

	return defaultLight
end

--
-- Management of cell profiles.
--

function interop.addProfileToCell(cellName, profileName)
	local definition = table.getset(interop.cellData.definitions, cellName, {})
	if (not table.find(definition, profileName)) then
		table.insert(definition, profileName)
	end
end

function interop.removeProfileFromCell(cellName, profileName)
	local definition = interop.cellData.definitions[cellName]
	if (definition) then
		table.removevalue(definition, profileName)
	end
end

function interop.getCellProfileDefinition(profileName)
	return interop.cellData.profiles[profileName]
end

function interop.addCellProfileDefinition(profileName)
	local existing = interop.cellData.profiles[profileName]
	if (existing) then
		return existing
	end

	local newDefinition = {}
	interop.cellData.profiles[profileName] = newDefinition
	return newDefinition
end

function interop.removeCellProfileDefinition(profileName)
	interop.cellData.profiles[profileName] = nil

	-- Remove from existing cell definitions.
	for cellName, profiles in pairs(interop.cellData.definitions) do
		table.removevalue(profiles, profileName)
	end
end

return interop
