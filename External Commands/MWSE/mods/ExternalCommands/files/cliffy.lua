
tes3.createReference({
	object = "cliff racer",
	position = tes3.player.position + tes3vector3.new(0, 0, 100),
	orientation = tes3.player.orientation,
	cell = tes3.player.cell
})
tes3.messageBox(json.encode(externalCommands.package))
