
--
-- This example places a cliff racer 100 units above the player.
--

-- Our parameters that we want to use. These can be easily changed.
local objectToSpawn = "cliff racer"
local positionAboveThePlayer = tes3.player.position + tes3vector3.new(0, 0, 100)

-- Our actual script logic. Create our object above the player.
tes3.createReference({
	object = objectToSpawn,
	position = positionAboveThePlayer,
	orientation = tes3.player.orientation,
	cell = tes3.player.cell
})
