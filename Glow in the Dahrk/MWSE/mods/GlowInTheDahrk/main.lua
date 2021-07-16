
local config = require("GlowInTheDahrk.config")
local interop = require("GlowInTheDahrk.interop")

--
-- Keep track of references we care about.
--

-- A true-valued, reference-keyed dictionary of our currently active references.
local trackedReferences = {}

-- A list of references currently needing updates.
local referenceUpdateQueue = {}

-- Add tracked references.
local function onReferenceActivated(e)
	if (not trackedReferences[e.reference]) then
		if (interop.checkSupport(e.reference)) then
			trackedReferences[e.reference] = true
			table.insert(referenceUpdateQueue, e.reference)
		else
			trackedReferences[e.reference] = false
		end
	end
end
event.register("referenceActivated", onReferenceActivated)

-- Remove tracked reference.
local function onReferenceDeactivated(e)
	if (trackedReferences[e.reference]) then
		table.removevalue(referenceUpdateQueue, e.reference)
	end
	trackedReferences[e.reference] = nil
end
event.register("referenceDeactivated", onReferenceDeactivated)

local function updateReferenceQueue()
	referenceUpdateQueue = {}
	for reference, supported in pairs(trackedReferences) do
		if (supported) then
			table.insert(referenceUpdateQueue, reference)
		end
	end
end

--
-- Figure out which cells are external to other cells
--

local cellRegionCache = {}

local function getRegion()
	local playerCell = tes3.getPlayerCell()
	if (not playerCell) then
		return
	end

	-- Does the current cell have a region?
	local playerCellRegion = playerCell.region
	if (playerCellRegion) then
		return playerCellRegion
	end

	-- Did we already find an answer last time?
	local cacheHit = cellRegionCache[playerCell]
	if (cacheHit) then
		return cacheHit
	end
	
	-- Look to see if anywhere exits to a place with a region.
	for ref in playerCell:iterateReferences(tes3.objectType.door) do
		local destination = ref.destination
		if (destination) then
			local destinationCell = destination.cell

			-- Does this cell have a region?
			local destinationRegion = destinationCell.region
			if (destinationRegion) then
				cellRegionCache[playerCell] = destinationRegion
				return destinationRegion
			end

			-- Does it point to a cell whose region we know?
			local destinationCacheHit = cellRegionCache[destinationCell]
			if (destinationCacheHit) then
				cellRegionCache[playerCell] = destinationCacheHit
				return destinationCacheHit
			end
		end
	end

	-- Still nothing? Just use the last exterior region if we can, but don't store it as reliable.
	local lastExterior = tes3.dataHandler.lastExteriorCell
	if (lastExterior) then
		return lastExterior.region
	end
end


--
-- Our actual reference updating code
--

local maxUpdatesPerFrame = 10

local function updateReferences(now)
	-- Bail if we have nothing to update.
	if (table.empty(trackedReferences)) then
		return
	end

	-- Refresh the queue if we need to.
	if (table.empty(referenceUpdateQueue)) then
		updateReferenceQueue()
	end

	-- Figure out what kind of cell we are in.
	local playerCell = tes3.getPlayerCell()
	local playerRegion = getRegion()
	local isInterior = playerCell.isInterior
	local useExteriorLogic = (not isInterior) or playerCell.behavesAsExterior

	-- Get faster access to some often-used variables.
	local worldController = tes3.worldController
	local weatherController = worldController.weatherController
	local gameHour = worldController.hour.value
	local dawnStart, dawnStop, duskStart, duskStop = interop.getDawnDuskHours()
	local dawnMidPoint = (dawnStop + dawnStart) / 2
	local duskMidPoint = (duskStop + duskStart) / 2
	local useVariance = config.useVariance
	local varianceScalar = config.varianceInMinutes / 60
	local addInteriorLights = config.addInteriorLights
	local addInteriorSunrays = config.addInteriorSunrays
	local weatherController = worldController.weatherController

	-- Calculate some of our lighting values.
	local currentWeatherBrightness = interop.getCurrentWeatherBrightness()
	local isOutsideLit = gameHour >= dawnStart and gameHour <= duskStop
	local currentRegionSunColor = playerRegion and interop.calculateRegionSunColor(playerRegion)

	-- Fade light in/out at dawn/dusk.
	local currentDimmer = 0.0
	if (dawnMidPoint < gameHour and gameHour < duskMidPoint) then
		currentDimmer = currentWeatherBrightness
	elseif (dawnStart <= gameHour and gameHour <= dawnMidPoint) then
		currentDimmer = currentWeatherBrightness * math.remap(gameHour, dawnStart, dawnMidPoint, 0.0, 1.0)
	elseif (duskMidPoint <= gameHour and gameHour <= duskStop) then
		currentDimmer = currentWeatherBrightness * (1.0 - math.remap(gameHour, duskMidPoint, duskStop, 0.0, 1.0))
	end

	-- Go through and update all our references.
	local queueLength = #referenceUpdateQueue
	for i = queueLength, math.max(queueLength - maxUpdatesPerFrame, 1), -1 do
		local reference = referenceUpdateQueue[i]
		local sceneNode = reference.sceneNode
		if (sceneNode) then
			local switchNode = sceneNode.children[1]
			if (switchNode) then
				-- Use hour variation if enabled.
				local hour = gameHour
				if (useExteriorLogic and useVariance) then
					local position = reference.position
					hour = hour + math.sin(position.x * 1.35 + position.y) * varianceScalar
				end

				-- Determine which new index to assign.
				local previousIndex = switchNode.switchIndex
				local index = 0
				if (useExteriorLogic) then
					if (hour < dawnMidPoint or hour > duskMidPoint) then
						index = 1
					end
				else
					if (isOutsideLit) then
						index = 2
					end
				end
				switchNode.switchIndex = index

				-- Do we need to add a light to an interior?
				if (not useExteriorLogic) then
					local cachedLight = nil
					local light = nil

					-- Perform state switches.
					if (previousIndex == 0 and index == 2) then
						-- Add light.
						if (addInteriorLights) then
							cachedLight = interop.getLightForMesh("meshes\\" .. reference.object.mesh)
							light = reference:getOrCreateAttachedDynamicLight(cachedLight)
						end

						-- Setup sunrays
						local currentActiveNode = switchNode.children[index + 1]
						local maybeRays = currentActiveNode.children[1]
						if (maybeRays and maybeRays.name == "rays") then
							maybeRays.appCulled = not addInteriorSunrays
						end
					elseif (previousIndex == 2 and index == 0) then
						-- Remove light.
						reference:deleteDynamicLightAttachment(true)
					end

					-- Update interior windows.
					if (index == 2) then
						-- Update lighting data.
						local lerpedColor = currentRegionSunColor
						light = light or reference.light
						if (light and light.RTTI and currentRegionSunColor) then
							cachedLight = cachedLight or interop.getLightForMesh("meshes\\" .. reference.object.mesh)
							lerpedColor = cachedLight.diffuse:lerp(currentRegionSunColor, 0.5)
	
							light.diffuse = lerpedColor
							light.dimmer = currentDimmer
						end

						-- Update rays.
						local currentActiveNode = switchNode.children[index + 1]
						if (addInteriorSunrays) then
							local maybeRays = currentActiveNode.children[1]
							if (maybeRays and maybeRays.name == "rays") then
								for ray in table.traverse({ maybeRays.children[1] }) do
									local materialProperty = ray:getProperty(0x2)
									if (materialProperty) then
										materialProperty.alpha = currentDimmer
									end
								end
							end
						end

						-- Update window color.
						for _, child in ipairs(currentActiveNode.children) do
							if (child.name ~= "rays") then
								local materialProperty = child:getProperty(0x2)
								if (materialProperty) then
									materialProperty.ambient = lerpedColor
									materialProperty.diffuse = lerpedColor
									materialProperty.emissive = lerpedColor * currentDimmer
								end
							end
						end
					end
				end
			end
		end

		-- Clear from queue.
		referenceUpdateQueue[i] = nil
	end
end


--
-- Custom light management
--

local function onMeshLoaded(e)
	local node = e.node

	-- Get the first child node.
	local dayNightSwitchNode = (#node.children > 0) and node.children[1] or nil

	-- Make sure the node has the name we care about.
	if (not dayNightSwitchNode or dayNightSwitchNode.name ~= "NightDaySwitch") then
		return
	end

	-- Look to see if it has a custom light.
	local attachLight = node:getObjectByName("AttachLight")
	if (attachLight and attachLight:isInstanceOfType(tes3.niType.NiNode)) then
		local light = attachLight.children[1]
		if (light and light:isInstanceOfType(tes3.niType.NiLight)) then
			-- Fixup some values for import. Namely the radius is stored as scale.
			light:setRadius(light.scale)
			-- light.name = "GitD Mesh-Customized Interior Light"

			-- Store the light for later cloning and detach it so no one else will get it added.
			interop.setLightForMesh(e.path, light)
			attachLight:detachChildAt(1)
		end
	end
end
event.register("meshLoaded", onMeshLoaded)


--
-- Keep track of when we need to update references.
--

local function onSimulate(e)
	if (e.menuMode or not interop.enabled) then
		return
	end

	updateReferences(e.timestamp)
end
event.register("simulate", onSimulate)


--
-- Create our Mod Config Menu
-- 
-- We do this in another file to cut down on the complexity of this file.
--

dofile("GlowInTheDahrk.mcm")


--
-- Expose some useful info for debugging.
--

local debug = { interop = interop, config = config }
debug.trackedReferences = trackedReferences
debug.referenceUpdateQueue = referenceUpdateQueue
debug.maxUpdatesPerFrame = maxUpdatesPerFrame
debug.getRegion = getRegion

local function addDebugCommands(e)
	e.sandbox.GlowInTheDahrk = debug
	e.sandbox.GitD = debug
end
event.register("UIEXP:sandboxConsole", addDebugCommands)

event.register("weatherChangedImmediate", function(e) mwse.log("Weather changed to %s.", table.find(tes3.weather, e.to.index)) end)
event.register("weatherTransitionStarted", function(e) mwse.log("Weather transition from %s to %s started.", table.find(tes3.weather, e.from.index), table.find(tes3.weather, e.to.index)) end)
event.register("weatherTransitionFinished", function(e) mwse.log("Weather transition to %s finished.", table.find(tes3.weather, e.to.index)) end)

function debug.printColorTimings()
	local weatherController = tes3.worldController.weatherController
	local fields = { "skyPostSunriseTime", "skyPostSunsetTime", "skyPreSunriseTime", "skyPreSunsetTime", "sunriseDuration", "sunriseHour", "sunsetDuration", "sunsetHour" }
	mwse.log("[Glow in the Dahrk] tes3weatherController timings:")
	for _, field in ipairs(fields) do
		mwse.log("  %s = %.2f", field, weatherController[field])
	end

	-- Figure out when our important sunrise times are.
	local sunriseStartTime = weatherController.sunriseHour - weatherController.skyPreSunriseTime
	local sunriseTotalDuration = weatherController.skyPostSunriseTime + weatherController.sunriseDuration + weatherController.skyPreSunriseTime
	local sunriseMidPoint = sunriseStartTime + (sunriseTotalDuration / 2)
	local sunriseStopTime = sunriseStartTime + sunriseTotalDuration
	mwse.log("  sunriseStartTime = %.2f", sunriseStartTime)
	mwse.log("  sunriseTotalDuration = %.2f", sunriseTotalDuration)
	mwse.log("  sunriseMidPoint = %.2f", sunriseMidPoint)
	mwse.log("  sunriseStopTime = %.2f", sunriseStopTime)

	-- Figure out when our important sunset times are.
	local sunsetStartTime = weatherController.sunsetHour - weatherController.skyPreSunsetTime
	local sunsetTotalDuration = weatherController.skyPostSunsetTime + weatherController.sunsetDuration + weatherController.skyPreSunsetTime
	local sunsetMidPoint = sunsetStartTime + (sunsetTotalDuration / 2)
	local sunsetStopTime = sunsetStartTime + sunsetTotalDuration
	mwse.log("  sunsetStartTime = %.2f", sunsetStartTime)
	mwse.log("  sunsetTotalDuration = %.2f", sunsetTotalDuration)
	mwse.log("  sunsetMidPoint = %.2f", sunsetMidPoint)
	mwse.log("  sunsetStopTime = %.2f", sunsetStopTime)
end
