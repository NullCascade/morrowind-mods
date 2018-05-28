
--[[
	Mod Initialization: Dynamic Difficulty
	Author: NullCascade

	This module is responsible for dynamically updating the difficulty based on the player's level,
	and current region.

]]--

-- Loud our config file.
local config = json.loadfile("nc_difficulty_config")

-- Function for how we're determining difficulty.
local function recalculateDifficulty()
	-- Get base difficulty.
	local difficulty = config.baseDifficulty or 0

	-- Scale with player level.
	local playerLevel = tes3.getPlayerRef().object.level
	difficulty = difficulty + config.increasePerLevel * (playerLevel - 1)

	-- Add any region modifiers.
	local lastExteriorCell = tes3.getDataHandler().lastExteriorCell
	if (lastExteriorCell ~= nil) then
		if (lastExteriorCell.region ~= nil) then
			local modifier = config.regionModifiers[lastExteriorCell.region.id]
			if (modifier ~= nil) then
				difficulty = difficulty + modifier
			end
		end
	end

	-- Are we capping difficulty?
	if (config.capDifficulty) then
		difficulty = math.clamp(difficulty, -100, 100)
	end

	-- Finally set the difficulty. It's a value of -1 to 1.
	tes3.getWorldController().difficulty = difficulty / 100
end

-- The events that we want to recalculate difficulty on.
if (config ~= nil) then
	event.register("loaded", recalculateDifficulty)
	event.register("levelUp", recalculateDifficulty)
	event.register("cellChanged", recalculateDifficulty)
else
	mwse.log("[nc-difficulty] Error: Could not load config file! Is the mod installed correctly?")
end
