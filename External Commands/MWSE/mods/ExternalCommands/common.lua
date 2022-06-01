local common = {}

function common.getPackage()
	return externalCommands.package --- @diagnostic disable-line
end

function common.getPositionBehind(reference, distance)
	local facing = reference.facing
	return reference.position - tes3vector3.new(math.sin(facing), math.cos(facing), 0.0) * distance
end

function common.getPositionBehindPlayer(distance)
	return common.getPositionBehind(tes3.player, distance)
end

function common.getRandomItem(reference)
	local inventory = assert(reference.object.inventory, "The target doesn't have an inventory.")
	local randomStack = math.random(0)
end

return common
