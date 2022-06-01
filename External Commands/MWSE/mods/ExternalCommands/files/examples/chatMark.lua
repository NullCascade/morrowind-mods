
--
-- This file stores the player's current position and orientation. The chatRecall example will then teleport the player to a chatm previous mark.
--
-- It is stored in a json file, so that subsequent characters (or reloads) can still take you to where was marked.
--

-- Get where we store the information.
local config = require("ExternalCommands.config")
local chatMarks = table.getset(config.moduleData, "chatMarks", {})

-- Get basic position data.
local markData = {
	position = tes3.player.position:copy(),
	facing = tes3.player.facing,
}

-- If they're in an interior, save the cell ID.
local playerCell = tes3.getPlayerCell()
if (playerCell.isInterior) then
	markData.cell = playerCell.id
end

-- Add it to the list of marks.
table.insert(chatMarks, markData)

-- Save the config file to serialize the changes.
mwse.saveConfig("External Commands", config)
