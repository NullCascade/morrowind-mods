
--
-- This example spawns a pair of dark brotherhood assassins behind the player.
--

-- A common library that houses some functions that multiple files may want to use.
local common = require("ExternalCommands.common")

-- Our parameters that we want to use. These can be easily changed.
local objectToSpawn = "db_assassin1b"
local positionBehindPlayer = common.getPositionBehindPlayer(200)
local numberToSpawn = 2

-- Our actual script logic. For 1 to numberToSpawn...
for _ = 1, numberToSpawn do
	-- ... create the above-defined object behind the player.
	tes3.createReference({
		object = objectToSpawn,
		position = positionBehindPlayer,
		orientation = tes3.player.orientation,
		cell = tes3.player.cell
	})
end
