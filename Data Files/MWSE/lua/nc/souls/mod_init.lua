
--[[
	Mod Initialization: Sounds of Souls
	Author: NullCascade

	
]]--

-- Mod configuration.
local config = json.loadfile("nc_souls_config")

-- Action string/integer mapping.
local soundTriggerActionNames = { "activate", "playerInventory", "cell" }
local soundTriggerAction = {
	["activate"] = 1,
	["playerInventory"] = 2,
	["cell"] = 3,
}


-- Determine the chance that a creature should make a sound
local function getCreatureSoundChance(creature, action)
	return config.environmentChecks[soundTriggerActionNames[action]].chance
end

-- Wrapper around getGetCreatureSoundChance that rolls the chance as well.
local function rollSoundPlayChance(creature, action)
	local roll = math.random(1, 100)
	local chance = getCreatureSoundChance(creature, action)
	if (roll > chance) then
		-- print("[nc-sos] Failed sound chance: " .. roll .. " vs. " .. chance)
		return false
	end

	return true
end

-- Creature sounds shouldn't be changing often. Keep a table of them for quick
-- lookup in the future.
local creatureSounds = {}

-- Manually fetches the sound for a given creature. This does not use the cached
-- table, A specific sound generator type must be specified.
local function rawGetSoundForCreature(creature, soundGenType)
	-- Before we do anything, find the base creature used for sounds.
	while (creature.soundCreature) do
		creature = creature.soundCreature
	end

	local soundGen = tes3.getSoundGenerator(creature.id, soundGenType)
	if (soundGen == nil) then
		return nil
	end

	return soundGen.sound
end

-- Returns a creature's sound table, which is a dictionary that maps a
-- tes3.soundGenType.* value to a given sound object.
local function getCreatureSoundTable(creature)
	-- Before we do anything, find the base creature used for sounds.
	while (creature.soundCreature) do
		creature = creature.soundCreature
	end

	-- Check for cache hit.
	local sounds = creatureSounds[creature]
	if (sounds ~= nil) then
		return sounds
	end

	-- Check for each of the main sounds.
	sounds = {}
	sounds[tes3.soundGenType.moan] = rawGetSoundForCreature(creature, tes3.soundGenType.moan)
	sounds[tes3.soundGenType.roar] = rawGetSoundForCreature(creature, tes3.soundGenType.roar)
	sounds[tes3.soundGenType.scream] = rawGetSoundForCreature(creature, tes3.soundGenType.scream)
	creatureSounds[creature] = sounds

	-- Return our table.
	return sounds
end

-- Gets a sound of a given type from a creature.
local function getCreatureSound(creature, soundGenType)
	return getCreatureSoundTable(creature)[soundGenType]
end

-- Randomly selects a sound for a given creature.
local function getRandomCreatureSound(creature)
	return table.choice(getCreatureSoundTable(creature))
end

-- 
local function getSoulVolume(creature)
	return math.clamp((creature and creature.soul or 0) * config.volume.soulValueScaler, config.volume.min, config.volume.max)
end

-- 
local function getSoulPitch(creature)
	return math.clamp((creature and creature.soul or 0) * config.pitch.soulValueScaler, config.pitch.min, config.pitch.max)
end

-- Determines if a given item/variable match contains a soul gem.
local function isFilledSoulGem(item, itemVariables)
	-- Make sure we got both variables.
	if (item == nil or itemVariables == nil) then
		return false
	end

	-- Make sure that we're looking at a misc item.
	if (item.objectType ~= tes3.objectType.miscItem) then
		return false
	end

	-- Make sure a soul is defined.
	if (itemVariables.soul == nil) then
		return false
	end

	return true
end

-- This function takes a list from getSoulGemListFromCell/Inventory and weighs the
-- souls by their relative values.
local function getChoiceFromSoulList(soulList, action)
	-- First we want to get the total soul value from the list.
	local totalSoul = 0
	for i = 1, #soulList do
		totalSoul = totalSoul + soulList[i].creature.soul
	end

	-- Determine which soul to use by generating a random number.
	local soulChoice = math.random(1, totalSoul)
	for i = 1, #soulList do
		soulChoice = soulChoice - soulList[i].creature.soul
		if (soulChoice < 0) then
			return soulList[i]
		end
	end

	return nil
end

-- Get a collection of filled soul gem references from the current cell.
local function getSoulGemListFromCell(cell)
	-- Make sure the cell is sane.
	if (cell == nil) then
		-- print("[nc-sos] No cell given!")
		return {}
	end

	-- Grow a collection of soul gems in the cell.
	local soulList = {}
	for reference in cell:iterateReferences(tes3.objectType.miscItem) do
		local item = reference.object
		local vars = reference.attachments.variables
		if (isFilledSoulGem(item, vars)) then
			table.insert(soulList, { reference = reference, creature = vars.soul})
		end
	end

	return soulList
end

-- Get a collection of filled soul gem references from the player's inventory.
local function getSoulGemListFromInventory(inventory)
	local playerRef = tes3.getPlayerRef()

	-- Iterate over the player's inventory and add soul gems to a list.
	local soulList = {}
	for itemStack in tes3.iterate(playerRef.object.inventory.iterator) do
		local item = itemStack.object
		if (itemStack.variables) then
			for i = 1, #itemStack.variables do
				local vars = itemStack.variables[i]
				if (isFilledSoulGem(item, vars)) then
					table.insert(soulList, { reference = playerRef, creature = vars.soul})
				end
			end
		end
	end

	return soulList
end

-- We want to force a check when someone activates the soulgem.
local function onActivate(e)
	local target = e.target
	local item = target.object
	local attachments = target.attachments
	local itemVariables = attachments and attachments.variables or nil

	-- Make sure that we're looking at a misc item.
	if (isFilledSoulGem(item, itemVariables) == false) then
		-- print("[nc-sos] Not a soul gem.")
		return
	end

	-- Roll chance to play the sound.
	if (rollSoundPlayChance(itemVariables.soul, soundTriggerAction.activate) == false) then
		return
	end

	-- Play one of the creature's sounds.
	local sound = getRandomCreatureSound(itemVariables.soul)
	tes3.playSound({ sound = sound, volume = getSoulVolume(itemVariables.soul), pitch = getSoulPitch(itemVariables.soul) })
	-- print("[nc-sos] Played sound!")
end
event.register("activate", onActivate)

local function playRandomInventorySoul()
	timer.start(math.random(config.environmentChecks.playerInventory.timerMin, config.environmentChecks.playerInventory.timerMax), playRandomInventorySoul)

	local soulConfig = getChoiceFromSoulList(getSoulGemListFromInventory(), soundTriggerAction.inventory)
	if (soulConfig == nil) then
		-- print("[nc-sos] No soul config found.")
		return
	end

	-- Roll chance to play the sound.
	if (rollSoundPlayChance(soulConfig.creature, soundTriggerAction.playerInventory) == false) then
		return
	end
	
	-- Play one of the creature's sounds.
	local sound = getRandomCreatureSound(soulConfig.creature)
	print(soulConfig.reference.id)
	tes3.playSound({ reference = soulConfig.reference, sound = sound, volume = getSoulVolume(soulConfig.creature), pitch = getSoulPitch(soulConfig.creature) })
	-- print("[nc-sos] Played sound!")
end

local function playRandomCellSoul()
	timer.start(math.random(config.environmentChecks.cell.timerMin, config.environmentChecks.cell.timerMax), playRandomCellSoul)

	local soulConfig = getChoiceFromSoulList(getSoulGemListFromCell(tes3.getPlayerCell()), soundTriggerAction.inventory)
	if (soulConfig == nil) then
		-- print("[nc-sos] No soul config found.")
		return
	end

	-- Roll chance to play the sound.
	if (rollSoundPlayChance(soulConfig.creature, soundTriggerAction.cell) == false) then
		return
	end
	
	-- Play one of the creature's sounds.
	local sound = getRandomCreatureSound(soulConfig.creature)
	tes3.playSound({ reference = soulConfig.reference, sound = sound, volume = getSoulVolume(soulConfig.creature), pitch = getSoulPitch(soulConfig.creature) })
	-- print("[nc-sos] Played sound!")
end

-- When we've finished loading, we want to start two timers to check for player/
local function onLoaded(e)
	timer.start(math.random(config.environmentChecks.playerInventory.timerMin, config.environmentChecks.playerInventory.timerMax), playRandomInventorySoul)
	timer.start(math.random(config.environmentChecks.cell.timerMin, config.environmentChecks.cell.timerMax), playRandomCellSoul)
end
event.register("loaded", onLoaded)
