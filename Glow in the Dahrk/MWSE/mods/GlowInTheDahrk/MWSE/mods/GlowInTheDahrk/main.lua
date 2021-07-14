--Which weather conditions will light up interior windows
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

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180725) then
	mwse.log("[GlowInTheDahrk] Build date of %s does not meet minimum build date of 20180725.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/glow/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/glow/", true)) then
		mwse.log("[GlowInTheDahrk] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else	
		mwse.log("[GlowInTheDahrk] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/glow' and restart Morrowind.")
		return
	end
end

-- Prepare configurationa nd any default values.
local config = mwse.loadConfig("Glow in the Dahrk")
config = config or {}
config.dawnHour = config.dawnHour or 6
config.duskHour = config.duskHour or 20
config.varianceInMinutes = config.varianceInMinutes or 30
if (config.useVariance == nil) then
    config.useVariance = true
end

local nightDaySwitchObjectCache = {}

-- Checks the above cache to see if object exists in it.
local function hasNightDaySwitch(object)
	-- Limit object types.
	if (object.objectType ~= tes3.objectType.static and object.objectType ~= tes3.objectType.activator) then
		return false
	end

	-- Check cache to see if this object has support.
	local cacheHit = nightDaySwitchObjectCache[object]
	if (cacheHit ~= nil) then
		return cacheHit
	end

	-- Get the object's scene graph object.
	local sgNode = object.sceneNode
	if (sgNode == nil) then
		nightDaySwitchObjectCache[object] = false
		return false
	end

	-- Get the first child node.
	local dayNightSwitchNode = (#sgNode.children > 0) and sgNode.children[1] or nil
	local match = (dayNightSwitchNode ~= nil)

	-- Make sure the node has the name we care about.
	if (match and dayNightSwitchNode.name ~= "NightDaySwitch") then
		match = false
	end
	
	-- Store the match.
	nightDaySwitchObjectCache[object] = match
	return match
end

-- Goes through every reference in the cell and updates its day/night switch based on the current hour and weather.
local function updateObjectsInInteriorCell(cell)
	local dawnHour = config.dawnHour
	local duskHour = config.duskHour

	local gameHour = tes3.worldController.hour.value
	for reference in cell:iterateReferences() do
		local sceneNode = reference.sceneNode
		if (sceneNode and hasNightDaySwitch(reference.object)) then
			-- Interior cells always light by game time
			local doLightInterior = false
			if (gameHour >= dawnHour and gameHour <= duskHour) then
				-- Check weather conditions
				if (brightWeathers[tes3.getCurrentWeather().index]) then
					doLightInterior = true
				end
			end
			
			local switchNode = sceneNode.children[1]
			if doLightInterior then
				switchNode.switchIndex = 2 --lights on
			else
				switchNode.switchIndex = 0 -- lights off
			end
		end
	end
end

-- Goes through every reference in the cell and updates its day/night switch based on the current hour.
local function updateObjectsInExteriorCell(cell)
	local dawnHour = config.dawnHour
	local duskHour = config.duskHour
	local useVariance = config.useVariance
	local varianceScalar = config.varianceInMinutes / 60

	local gameHour = tes3.worldController.hour.value
	for reference in cell:iterateReferences() do
		local sceneNode = reference.sceneNode
		if (sceneNode and hasNightDaySwitch(reference.object)) then
			local switchNode = sceneNode.children[1]

			-- For exterior cells we add some randomness to stagger window lighting.
			local hour = gameHour
			if (useVariance) then
				local position = reference.position
				hour = hour + math.sin(position.x * 1.35 + position.y) * varianceScalar
			end
			
			if (hour < dawnHour or hour > duskHour) then
				switchNode.switchIndex = 1
			else
				switchNode.switchIndex = 0
			end
		end
	end
end

-- Get the player cell, and update it and/or surrounding cells.
local function updateObjects()
	local cell = tes3.getPlayerCell()
	if (cell.isInterior) then
		if (cell.behavesAsExterior) then
			updateObjectsInExteriorCell(cell)
		else
			updateObjectsInInteriorCell(cell)
		end
	else
		local exteriorCells = tes3.dataHandler.exteriorCells
		for i = 1, #exteriorCells do
			updateObjectsInExteriorCell(exteriorCells[i].cell)
		end
	end
end

-- Manual flag for forcing an update. If set.
local needUpdate = false

-- The timestamp of the last time we updated glow objects.
local lastUpdateTimestamp = 0

-- Look every simulation frame to see if we need to update objects.
local function onSimulate(e)
	local timeDifference = e.timestamp - lastUpdateTimestamp
	if (needUpdate or timeDifference > 0.08) then
		updateObjects()

		needUpdate = false
		lastUpdateTimestamp = e.timestamp
	end
end
event.register("simulate", onSimulate)

-- When we load the game or change cell, flag an update.
local function flagNeedForUpdate()
	needUpdate = true
end
event.register("loaded", flagNeedForUpdate)
event.register("cellChanged", flagNeedForUpdate)

-- Setup MCM.
local modConfig = require("GlowInTheDahrk.mcm")
modConfig.config = config
modConfig.resetAutosaveTimer = resetAutosaveTimer
local function registerModConfig()
	mwse.registerModConfig("Glow in the Dahrk", modConfig)
end
event.register("modConfigReady", registerModConfig)
