
--
-- This command will teleport the player to Fargoth, wherever he might be.
--

-- Our parameters that we want to use. These can be easily changed.
local fargoth = tes3.getReference("fargoth")

-- Our actual script logic. Relocate to Fargoth.
tes3.positionCell({
	reference = tes3.player,
	cell = fargoth.cell,
	position = fargoth.position,
	orientation = fargoth.orientation,
	teleportCompanions = true,
})
