local config = require("GlowInTheDahrk.config")
local interop = require("GlowInTheDahrk.interop")
local GitD_debug = require("GlowInTheDahrk.debug")

--[[
	Todo list:
		x Correctly toggle sunrays when using the MCM.
		? Figure out how to cull objects from dynamic effects to prevent bleed between walls/floors.
		- Figure out what to do with plazas.
--]]

--
-- Keep track of references we care about.
--

--- A reference-keyed dictionary of our currently active references, mapping them to its mesh data.
---
--- False values means that we have checked support for this object before, don't support it, and don't need to do deep checks in the future.
--- @type table<tes3reference,table.GitD.meshData|boolean>
local trackedReferences = {}

--- A list of references currently needing updates.
--- @type tes3reference[]
local referenceUpdateQueue = {}

-- Add tracked references.
local function onReferenceActivated(e)
	if (not trackedReferences[e.reference]) then
		local supported, data = interop.checkSupport(e.reference)
		if (supported) then
			trackedReferences[e.reference] = data
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
	table.clear(referenceUpdateQueue)
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

local colorBlack = niColor.new(0.0, 0.0, 0.0)

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

	-- Allow forcing weather.
	if (GitD_debug.forceWeather) then
		playerRegion.weather = GitD_debug.forceWeather
	end

	-- Get faster access to some often-used variables.
	local worldController = tes3.worldController
	local gameHour = worldController.hour.value
	local sunriseStart, sunriseMidPoint, sunriseStop, sunsetStart, sunsetMidPoint, sunsetStop = interop.getSunHours()
	local sunriseMidPoint = (sunriseStart + sunriseStop) / 2
	local sunsetMidPoint = (sunsetStart + sunsetStop) / 2
	local useVariance = config.useVariance
	local varianceScalar = config.varianceInMinutes / 60
	local addInteriorLights = config.addInteriorLights
	local addInteriorSunrays = config.addInteriorSunrays

	-- Calculate some of our lighting values.
	local currentWeatherBrightness = interop.getCurrentWeatherBrightness()
	local isOutsideLit = gameHour >= sunriseStart and gameHour <= sunsetStop
	local currentRegionSunColor = playerRegion and interop.calculateRegionSunColor(playerRegion)
	
	-- Fade light in/out at dawn/dusk.
	local dimmer = 0.0
	if (sunriseMidPoint < gameHour and gameHour < sunsetMidPoint) then
		dimmer = currentWeatherBrightness
	elseif (sunriseStart <= gameHour and gameHour <= sunriseMidPoint) then
		dimmer = currentWeatherBrightness * math.remap(gameHour, sunriseStart, sunriseMidPoint, 0.0, 1.0)
	elseif (sunsetMidPoint <= gameHour and gameHour <= sunsetStop) then
		dimmer = currentWeatherBrightness * math.remap(gameHour, sunsetStop, sunsetMidPoint, 0.0, 1.0)
	end
	
	-- Go through and update all our references.
	local queueLength = #referenceUpdateQueue
	for i = queueLength, math.max(queueLength - maxUpdatesPerFrame, 1), -1 do
		local reference = referenceUpdateQueue[i]
		local meshData = trackedReferences[reference]
		local sceneNode = reference.sceneNode
		if (sceneNode) then
			local cellData = meshData.cellData[playerCell.id] or {}

			local indexOff = meshData.indexOff
			local indexOn = meshData.indexOn
			local indexInDay = meshData.indexInDay

			local switchNode = sceneNode.children[meshData.switchChildIndex]
			if (switchNode) then
				-- Use hour variation if enabled.
				local hour = gameHour
				if (useExteriorLogic and useVariance) then
					local position = reference.position
					hour = hour + math.sin(position.x * 1.35 + position.y) * varianceScalar
				end

				-- If we want to flip the logic, offset the hours by 12.
				local dimmer = dimmer
				local isOutsideLit = isOutsideLit
				if (cellData.flipDayNightRole) then
					hour = (hour + 12) % 24

					-- Recalculate isOutsideLit
					isOutsideLit = hour >= sunriseStart and hour <= sunsetStop

					-- Recalculate dimmer.
					if (sunriseMidPoint < hour and hour < sunsetMidPoint) then
						dimmer = currentWeatherBrightness
					elseif (sunriseStart <= hour and hour <= sunriseMidPoint) then
						dimmer = currentWeatherBrightness * math.remap(hour, sunriseStart, sunriseMidPoint, 0.0, 1.0)
					elseif (sunsetMidPoint <= hour and hour <= sunsetStop) then
						dimmer = currentWeatherBrightness * math.remap(hour, sunsetStop, sunsetMidPoint, 0.0, 1.0)
					end
				end

				-- Determine which new index to assign.
				local previousIndex = switchNode.switchIndex + 1
				local index = indexOff
				if (useExteriorLogic) then
					if (hour < sunriseStart or hour > sunsetStop) then
						index = indexOn
					end
				else
					if (isOutsideLit) then
						index = indexInDay
					end
				end
				switchNode.switchIndex = index - 1

				-- Do we need to add a light to an interior?
				if (not useExteriorLogic) then
					local cachedLight = nil
					local light = nil

					-- Perform state switches.
					if (previousIndex == indexOff and index == indexInDay) then
						-- Add light.
						if (addInteriorLights and meshData.supportsLight) then
							cachedLight = meshData.light or interop.getDefaultLight()
							local attachment = reference:getOrCreateAttachedDynamicLight(cachedLight:clone())
							light = attachment and attachment.light
						end

						-- Setup sunrays
						if (meshData.interiorRayIndex) then
							switchNode.children[index].children[meshData.interiorRayIndex].appCulled = not addInteriorSunrays
						end
					elseif (previousIndex == indexInDay and index == indexOff and meshData.supportsLight) then
						-- Remove light.
						reference:deleteDynamicLightAttachment(true)
					end

					-- Update interior windows.
					if (index == indexInDay) then
						-- Update lighting data.
						local lerpedColor = currentRegionSunColor
						if (meshData.supportsLight) then
							light = light or reference.light
							if (light and currentRegionSunColor) then
								cachedLight = cachedLight or meshData.light or interop.getDefaultLight()
								lerpedColor = cachedLight.diffuse * currentRegionSunColor

								light.diffuse = lerpedColor
								light.dimmer = dimmer
							end
						end

						-- Update rays.
						local interiorNode = switchNode.children[index]
						if (addInteriorSunrays and meshData.interiorRayIndex) then
							local rays = interiorNode.children[meshData.interiorRayIndex]
							for ray in table.traverse({ rays }) do
								local materialProperty = ray.materialProperty
								if (materialProperty) then
									materialProperty.ambient = lerpedColor
									materialProperty.diffuse = lerpedColor
									materialProperty.emissive = lerpedColor * dimmer
									materialProperty.alpha = dimmer
								end
							end
						end

						-- Update window color.
						if (meshData.litInteriorWindowShapesIndexes) then
							for _, index in ipairs(meshData.litInteriorWindowShapesIndexes) do
								local materialProperty = interiorNode.children[index].materialProperty
								if (materialProperty) then
									materialProperty.ambient = lerpedColor
									materialProperty.diffuse = lerpedColor
									materialProperty.emissive = lerpedColor * dimmer
								end
							end
						end
					elseif (index == indexOff) then
						local unlitInteriorNode = switchNode.children[indexOff]

						-- Update window color.
						if (meshData.unlitInteriorWindowShapesIndexes) then
							for _, index in ipairs(meshData.unlitInteriorWindowShapesIndexes) do
								local materialProperty = unlitInteriorNode.children[index].materialProperty
								if (materialProperty) then
									materialProperty.ambient = currentRegionSunColor
									materialProperty.diffuse = currentRegionSunColor
									materialProperty.emissive = colorBlack
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
-- Handle initial loading of meshes.
-- Here we will find out if this is a GitD-supporting mesh and store later data for use.
--

local meshesPathPrefixLength = string.len("meshes\\")

local function getChildByName(collection, name)
	for i, child in ipairs(collection) do
		if (child and child.name and child.name:lower() == name) then
			return i
		end
	end
end

local function onMeshLoaded(e)
	---@type niNode
	local node = e.node

	-- Make sure the node has the name we care about.
	local switchChildIndex = getChildByName(node.children, "nightdayswitch")
	if (not switchChildIndex) then
		return
	end

	-- Remove the meshes\ prefix.
	local path = string.sub(e.path, meshesPathPrefixLength + 1, string.len(e.path))
	local data = interop.createMeshData(path)
	data.switchChildIndex = switchChildIndex

	-- Get the first child node.
	local dayNightSwitchNode = node.children[data.switchChildIndex]
	data.indexOff = getChildByName(dayNightSwitchNode.children, "off") or 1
	data.indexOn = getChildByName(dayNightSwitchNode.children, "on") or 2
	data.indexInDay = getChildByName(dayNightSwitchNode.children, "int-day") or 3

	-- Does the mesh have interior light capabilities?
	if (#dayNightSwitchNode.children >= data.indexInDay) then
		-- Look to see if it has a custom light.
		local attachLight = node:getObjectByName("AttachLight")
		if (attachLight) then
			data.supportsLight = true

			local light = attachLight.children[1]
			if (light and light:isInstanceOfType(tes3.niType.NiLight)) then
				-- Fixup some values for import. Namely the radius is stored as scale.
				light:setRadius(light.scale)
				-- light.name = "GitD Mesh-Customized Interior Light"

				-- Store the light for later cloning and detach it so no one else will get it added.
				data.light = light
				attachLight:detachChildAt(1)
			end
		end

		local interiorLights = dayNightSwitchNode.children[data.indexInDay]
		data.interiorRayIndex = getChildByName(interiorLights.children, "rays")

		-- Make a guess at if this is a modern mesh.
		if (not data.supportsLight and data.interiorRayIndex ~= 1) then
			data.legacyMesh = true
			mwse.log("[Glow In The Dahrk] Converting legacy mesh: %s", path)
		end

		-- If it is an old mesh try to fix up rays.
		if (data.legacyMesh and data.interiorRayIndex) then
			local raysNode = dayNightSwitchNode.children[data.indexInDay].children[data.interiorRayIndex]
			for shape in table.traverse({ raysNode }) do
				local materialProperty = shape.materialProperty
				if (materialProperty and shape:isInstanceOfType(tes3.niType.NiTriShape)) then
					-- Ensure unique materials.
					if (materialProperty.refCount > 2) then
						materialProperty = materialProperty:clone()
						shape.materialProperty = materialProperty
					end

					-- Remove vertex coloring if we need to.
					if (shape.data and shape.data.colors and #shape.data.colors > 0) then
						shape.data = shape.data:copy({ colors = false })
						shape.data:markAsChanged()
					end

					-- Make sure we don't have a glow map.
					local texturingProperty = shape.texturingProperty
					if (texturingProperty.glowMap) then
						texturingProperty.glowMap = nil
					end

					shape:updateProperties()
					shape:update()
				end
			end
		end

		-- See if we can clear up vcol on the interior window mesh.
		-- Also see what shapes we will later want to update when coloring windows.
		local litInteriorWindowShapesIndexes = {}
		local lastShape = nil ---@type niTriShape
		for i, shape in ipairs(interiorLights.children) do
			if (shape) then
				local texturingProperty = shape.texturingProperty
				local materialProperty = shape.materialProperty
				if (texturingProperty and materialProperty and shape:isInstanceOfType(tes3.niType.NiTriShape)) then
					table.insert(litInteriorWindowShapesIndexes, i)
					lastShape = shape

					-- If it is an old mesh try to fix up windows.
					if (data.legacyMesh) then
						-- Ensure unique materials.
						if (materialProperty.refCount > 2) then
							materialProperty = materialProperty:clone()
							shape.materialProperty = materialProperty
						end

						-- Remove vertex coloring if we need to.
						if (shape.data and shape.data.colors and #shape.data.colors > 0) then
							shape.data = shape.data:copy({ colors = false })
							shape.data:markAsChanged()
						end

						-- Make sure we don't have a glow map.
						if (texturingProperty.glowMap) then
							texturingProperty.glowMap = nil
						end

						shape:updateProperties()
						shape:update()
					end
				end
			end
		end
		if (#litInteriorWindowShapesIndexes > 0) then
			data.litInteriorWindowShapesIndexes = litInteriorWindowShapesIndexes
		end

		-- Do we have info to create a new light attachment point?
		if (not attachLight and lastShape) then
			-- Try to make one that is positioned reasonably.
			local nodeBoundingBox = node:createBoundingBox()
			local shapeBoundingBox = lastShape:createBoundingBox()
			if (nodeBoundingBox and shapeBoundingBox) then
				attachLight = niNode.new()
				attachLight.name = "AttachLight"

				-- Get a point 25% of the way from the tile's center towards the window.
				local nodeBoundingBoxCenter = (nodeBoundingBox.max + nodeBoundingBox.min) * 0.5
				local shapeBoundingBoxCenter = (shapeBoundingBox.max + shapeBoundingBox.min) * 0.5
				attachLight.translation = nodeBoundingBoxCenter:lerp(shapeBoundingBoxCenter, 0.25)

				data.supportsLight = true
				node:attachChild(attachLight)
			end
		end
	end

	-- We also need to know about unlit interior windows.
	if (#dayNightSwitchNode.children >= data.indexOff) then
		-- See what shapes we will later want to update when coloring nighttime windows.
		local unlitInteriorWindowShapesIndexes = {}
		for i, shape in ipairs(dayNightSwitchNode.children[data.indexOff].children) do
			if (shape) then
				local texturingProperty = shape.texturingProperty
				local materialProperty = shape.materialProperty
				if (texturingProperty and materialProperty and shape:isInstanceOfType(tes3.niType.NiTriShape)) then
					table.insert(unlitInteriorWindowShapesIndexes, i)

					-- If it is an old mesh try to fix up windows.
					if (data.legacyMesh) then
						-- Ensure unique materials.
						if (materialProperty.refCount > 2) then
							materialProperty = materialProperty:clone()
							shape.materialProperty = materialProperty
						end

						-- Remove vertex coloring if we need to.
						if (shape.data and shape.data.colors and #shape.data.colors > 0) then
							shape.data = shape.data:copy({ colors = false })
							shape.data:markAsChanged()
						end

						-- Make sure we don't have a glow map.
						if (texturingProperty.glowMap) then
							texturingProperty.glowMap = nil
						end

						shape:updateProperties()
						shape:update()
					end
				end
			end
		end
		if (#unlitInteriorWindowShapesIndexes > 0) then
			data.unlitInteriorWindowShapesIndexes = unlitInteriorWindowShapesIndexes
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
-- Expose some useful info for GitD_debugging.
--

GitD_debug.cellRegionCache = cellRegionCache
GitD_debug.getRegion = getRegion
GitD_debug.referenceUpdateQueue = referenceUpdateQueue
GitD_debug.trackedReferences = trackedReferences

function GitD_debug.listActiveReferences()
	local results = {}
	for reference, data in pairs(trackedReferences) do
		if (data) then
			table.insert(results, reference.id)
		end
	end
	tes3ui.log(table.concat(results, ", "))
end

local function addGitD_DebugCommands(e)
	e.sandbox.GlowInTheDahrk = GitD_debug
	e.sandbox.GitD = GitD_debug
	e.sandbox.gitd = GitD_debug
	e.sandbox.GITD = GitD_debug
end
event.register("UIEXP:sandboxConsole", addGitD_DebugCommands)
