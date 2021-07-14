
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
event.register("referenceActivated", onReferenceActivated)

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
				if (isInterior and addInteriorLights) then
					if (previousIndex == 0 and index == 2) then
						-- Add light.
						local lightNode = reference:getOrCreateAttachedDynamicLight()
						local light = lightNode.light
						light.diffuse.r = 1
						light.diffuse.g = 1
						light.diffuse.b = 1
						light:setAttenuationForRadius(200)
					elseif (previousIndex == 2 and index == 0) then
						-- Remove light.
						reference:detachDynamicLightFromAffectedNodes()
						reference:deleteDynamicLightAttachment()
					end
				end
			end
		end
	end
end

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
