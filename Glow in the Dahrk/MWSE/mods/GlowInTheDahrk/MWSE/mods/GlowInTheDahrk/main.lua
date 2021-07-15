
local config = require("GlowInTheDahrk.config")
local interop = require("GlowInTheDahrk.interop")

-- 
-- Keep track of references we care about.
-- 

-- A true-valued, reference-keyed dictionary of our currently active references.
local trackedReferences = {}

-- Manual flag for forcing an update.
local needUpdate = false
local function forceUpdate(e)
	needUpdate = true
end

-- Add tracked references.
local function onReferenceActivated(e)
	if (interop.checkSupport(e.reference)) then
		trackedReferences[e.reference] = true
		forceUpdate()
	end
end
event.register("referenceActivated", onReferenceActivated)

-- Remove tracked reference.
local function onReferenceDeactivated(e)
	trackedReferences[e.reference] = nil
end
event.register("referenceDeactivated", onReferenceDeactivated)

--
-- Our actual reference updating code
--

local function isCellExterior(cell)
	return not cell.isInterior
end

local function updateReferences()
	-- Figure out what kind of cell we are in.
	local playerCell = tes3.getPlayerCell()
	local isInterior = playerCell.isInterior
	local useExteriorLogic = (not isInterior) or playerCell.behavesAsExterior

	-- Get faster access to some often-used variables.
	local gameHour = tes3.worldController.hour.value
	local dawnHour = config.dawnHour
	local duskHour = config.duskHour
	local useVariance = config.useVariance
	local varianceScalar = config.varianceInMinutes / 60
	local addInteriorLights = config.addInteriorLights
	local addInteriorSunrays = config.addInteriorSunrays

	-- Calculate some of our lighting values.
	local isOutsideLit = gameHour >= dawnHour and gameHour <= duskHour and interop.isCurrentWeatherBright()

	-- Go through and update all our references.
	for reference in pairs(trackedReferences) do
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
					if (hour < dawnHour or hour > duskHour) then
						index = 1
					end
				else
					if (isOutsideLit) then
						index = 2
					end
				end
				switchNode.switchIndex = index

				-- Do we need to add a light to an interior?
				if (isInterior) then
					if (previousIndex == 0 and index == 2) then
						-- Add light.
						if (addInteriorLights) then
							local light = interop.getLightForMesh("meshes\\" .. reference.object.mesh)
							reference:getOrCreateAttachedDynamicLight(light)
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
				end
			end
		end
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
			light.scale = 1.0
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

-- The timestamp of the last time we updated glow objects.
local nextUpdateTime = 0

event.register("cellChanged", forceUpdate)

local function onSimulate(e)
	local now = e.timestamp
	if (needUpdate or now > nextUpdateTime) then
		needUpdate = false
		updateReferences()

		-- Figure out when we next need to trigger an update.
		nextUpdateTime = now + 0.08
	end
end
event.register("simulate", onSimulate)

--
-- Create our Mod Config Menu
-- 
-- We do this in another file to cut down on the complexity of this file.
--

dofile("GlowInTheDahrk.mcm")
