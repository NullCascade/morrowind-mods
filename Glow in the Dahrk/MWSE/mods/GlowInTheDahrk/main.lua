local config = require("GlowInTheDahrk.config")
local interop = require("GlowInTheDahrk.interop")
local debug = require("GlowInTheDahrk.debug")

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
	local dawnMidPoint = (dawnStart + dawnStop) / 2
	local duskMidPoint = (duskStart + duskStop) / 2
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
		currentDimmer = currentWeatherBrightness * math.remap(gameHour, duskStop, duskMidPoint, 0.0, 1.0)
	end

	-- Go through and update all our references.
	local queueLength = #referenceUpdateQueue
	for i = queueLength, math.max(queueLength - maxUpdatesPerFrame, 1), -1 do
		local reference = referenceUpdateQueue[i]
		local sceneNode = reference.sceneNode
		if (sceneNode) then
			local meshData = trackedReferences[reference]

			local switchNode = sceneNode.children[meshData.switchChildIndex]
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
						if (addInteriorLights and meshData.supportsLight) then
							cachedLight = meshData.light or interop.getDefaultLight()
							local attachment = reference:getOrCreateAttachedDynamicLight(cachedLight:clone())
							light = attachment and attachment.light
						end

						-- Setup sunrays
						if (meshData.interiorRayIndex) then
							switchNode.children[index + 1].children[meshData.interiorRayIndex].appCulled = not addInteriorSunrays
						end
					elseif (previousIndex == 2 and index == 0 and meshData.supportsLight) then
						-- Remove light.
						reference:deleteDynamicLightAttachment(true)
					end

					-- Update interior windows.
					if (index == 2) then
						-- Update lighting data.
						local lerpedColor = currentRegionSunColor
						if (meshData.supportsLight) then
							light = light or reference.light
							if (light and currentRegionSunColor) then
								cachedLight = cachedLight or meshData.light or interop.getDefaultLight()
								lerpedColor = cachedLight.diffuse:lerp(currentRegionSunColor, 0.5)

								light.diffuse = lerpedColor
								light.dimmer = currentDimmer
							end
						end

						-- Update rays.
						local interiorNode = switchNode.children[index + 1]
						if (addInteriorSunrays and meshData.interiorRayIndex) then
							local rays = interiorNode.children[meshData.interiorRayIndex]
							for ray in table.traverse({ rays }) do
								local materialProperty = ray.materialProperty
								if (materialProperty) then
									materialProperty.alpha = currentDimmer
								end
							end
						end

						-- Update window color.
						if (meshData.interiorWindowShapes) then
							for _, index in ipairs(meshData.interiorWindowShapes) do
								local materialProperty = interiorNode.children[index].materialProperty
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

	-- Does the mesh have interior light capabilities?
	local interiorLightIndex = 2 + 1 -- Offset by one.
	if (#dayNightSwitchNode.children >= interiorLightIndex) then
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

		local interiorLights = dayNightSwitchNode.children[interiorLightIndex]
		data.interiorRayIndex = getChildByName(interiorLights.children, "rays")

		-- Make a guess at if this is a modern mesh.
		if (not data.supportsLight and data.interiorRayIndex ~= 1) then
			data.legacyMesh = true
			mwse.log("[Glow In The Dahrk] Converting legacy mesh: %s", path)
		end

		-- If it is an old mesh try to fix up rays.
		if (data.legacyMesh and data.interiorRayIndex) then
			local raysNode = dayNightSwitchNode.children[interiorLightIndex].children[data.interiorRayIndex]
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
		local interiorWindowShapes = {}
		local lastShape = nil
		for i, shape in ipairs(interiorLights.children) do
			local texturingProperty = shape.texturingProperty
			local materialProperty = shape.materialProperty
			if (texturingProperty and materialProperty and shape:isInstanceOfType(tes3.niType.NiTriShape)) then
				table.insert(interiorWindowShapes, i)
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
		if (#interiorWindowShapes > 0) then
			data.interiorWindowShapes = interiorWindowShapes
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

debug.cellRegionCache = cellRegionCache
debug.getRegion = getRegion
debug.referenceUpdateQueue = referenceUpdateQueue
debug.trackedReferences = trackedReferences

local function addDebugCommands(e)
	e.sandbox.GlowInTheDahrk = debug
	e.sandbox.GitD = debug
end
event.register("UIEXP:sandboxConsole", addDebugCommands)
