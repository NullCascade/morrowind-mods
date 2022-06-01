
--
-- This file pairs with the chatMark file. It will teleport the player to a random one.
--

-- Get where we store the information.
local config = require("ExternalCommands.config")
local chatMarks = config.moduleData.chatMarks

-- Do we not have any yet?
if (not chatMarks) then
	tes3.messageBox("Someone just tried to recall us to nowhere!")
	return
end

-- If we do have data, choose a random one.
local randomData = table.choice(chatMarks)

-- Then teleport the player there.
tes3.positionCell({
	reference = tes3.player,
	cell = randomData.cell,
	position = randomData.position,
	orientation = tes3vector3.new(0, 0, randomData.facing),
	teleportCompanions = true,
})
