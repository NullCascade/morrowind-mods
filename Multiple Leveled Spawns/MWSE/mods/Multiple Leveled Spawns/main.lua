
local config = require("Multiple Leveled Spawns.config")
local log = require("Multiple Leveled Spawns.log")

--- @param spawner tes3reference
--- @param currentSpawnCount number The number of spawns chained.
local function checkToDoubleSpawn(spawner, currentSpawnCount)
	local leveledList = spawner.object --- @type tes3leveledCreature
	assert(leveledList.objectType == tes3.objectType.leveledCreature)

	if (not config.enabled) then
		return
	end

	if (currentSpawnCount >= config.maxSpawns) then
		log:debug("[%s @ %s] No spawn, max spawn count reached.", leveledList, spawner.position)
		spawner.data.multiSpawnChecked = true
		return
	end

	if (spawner.data.multiSpawnChecked) then
		log:debug("[%s @ %s] No spawn, already checked for spawn.", leveledList, spawner.position)
		spawner.data.multiSpawnChecked = true
		return
	end

	local roll = math.random()
	if (roll > config.chanceOfAdditionalSpawn) then
		log:debug("[%s @ %s] No spawn, failed roll (%.2f vs. %.2f).", leveledList, spawner.position, roll, config.chanceOfAdditionalSpawn)
		spawner.data.multiSpawnChecked = true
		return
	end

	local spawn = leveledList:pickFrom()
	if (spawn == nil) then
		log:debug("[%s @ %s] No spawn, pick failed (chance for none: %d%%).", spawner, spawner.position, leveledList.chanceForNothing)
		spawner.data.multiSpawnChecked = true
		return
	end

	local reference = tes3.createReference({
		object = spawn,
		cell = spawner.cell,
		position = spawner.position,
		orientation = spawner.orientation,
	})
	log:debug("[%s @ %s] Spawned %s as an extra reference. Roll was %.2f. This is spawn #%d.", leveledList, spawner.position, reference.baseObject, roll, currentSpawnCount + 1)

	-- Repeat the process.
	checkToDoubleSpawn(spawner, currentSpawnCount + 1)

	spawner.data.multiSpawnChecked = true
end

--- @param e referenceActivatedEventData
local function onReferenceActivated(e)
	local reference = e.reference
	local spawner = reference.leveledBaseReference
	if (not spawner) then
		return
	end

	local leveledList = spawner.object --- @type tes3leveledCreature
	if (leveledList.objectType ~= tes3.objectType.leveledCreature) then
		return
	end

	checkToDoubleSpawn(spawner, 1)
end
event.register(tes3.event.referenceActivated, onReferenceActivated)

dofile("Multiple Leveled Spawns.mcm")