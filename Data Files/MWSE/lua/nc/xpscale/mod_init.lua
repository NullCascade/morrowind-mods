
--[[
	Mod Initialization: Proportional Progression
	Author: NullCascade

	This module allows configuring the rate at which skills level.
]]--

-- Our parsed config.
local config = nil

-- Loads config into the above variable. We change some names in this process, and massage skill names into numbers.
local function loadConfig()
	-- Raw config file data. We'll want to manipulate it.
	local rawConfig = json.loadfile("nc_xpscale_config")

	config = {}

	-- Get the global scale, or assume it is 1.
	config.scale = rawConfig.scale or 1.0

	-- Go through the user-friendly names, convert them to skill indexes, and add them to the config.
	if (rawConfig.skillSpecific.use) then
		local skillSpecific = {}
		for k, v in pairs(rawConfig.skillSpecific.values) do
			skillSpecific[tes3.skill[k]] = v
		end
		config.skill = skillSpecific
	end

	-- Convert keys to numbers, store them in config.level.
	if (rawConfig.levelSpecific.use) then
		local levelSpecific = {}
		for k, v in pairs(rawConfig.levelSpecific.values) do
			levelSpecific[tonumber(k)] = v
		end
		config.level = levelSpecific
	end

	-- Convert keys to numbers, store them in config.skillLevel.
	if (rawConfig.skillLevelSpecific.use) then
		local skillLevelSpecific = {}
		for k, v in pairs(rawConfig.skillLevelSpecific.values) do
			skillLevelSpecific[tonumber(k)] = v
		end
		config.skillLevel = skillLevelSpecific
	end

	-- Print the loaded config to the log.
	print("[nc-xpscale] Loaded config:")
	print(json.encode(config, {indent = true}))
end
loadConfig()

-- Fetches the highest key in table that doesn't go over value.
local function getClosestConfigValue(table, value)
	local highestMatchingLevel = 0
	for configLevel, scale in pairs(table) do
		if (configLevel > highestMatchingLevel and configLevel <= value) then
			highestMatchingLevel = configLevel
		end
	end

	return highestMatchingLevel
end

-- Determines what modifier is.
local function calculateProgressionModifier(skillId, initialProgress)
	-- We start with the global scale.
	local modifier = config.scale

	-- If we're using skill modifiers, bring that in.
	if (config.skill ~= nil) then
		modifier = modifier * config.skill[skillId]
	end

	-- If we're using player level modifiers, find the closest and use it.
	if (config.level ~= nil) then
		local index = getClosestConfigValue(config.level, tes3.getPlayerRef().object.level)
		modifier = modifier * config.level[index]
	end

	-- If we're using skill level modifiers, find the closest and use it.
	if (config.skillLevel ~= nil) then
		local index = getClosestConfigValue(config.skillLevel, tes3.getMobilePlayer().skills[skillId+1].base)
		modifier = modifier * config.skillLevel[index]
	end

	return modifier
end

local function onExerciseSkill(e)
	e.progress = e.progress * calculateProgressionModifier(e.skill, e.progress)
end
event.register("exerciseSkill", onExerciseSkill)
