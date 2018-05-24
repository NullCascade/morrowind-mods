local interop = require("nc.consume.interop")

local this = {}

function this.isPotionSelfTargeting(potion)
	for i = 1, #potion.effects do
		local effect = potion.effects[i]
		if (effect.rangeType ~= tes3.effectRange.self) then
			return false
		end
	end
	
	return true
end

function this.basicPotionChecks(equipEvent)
	local reference = equipEvent.reference
	local potion = equipEvent.item

	-- We only care about the player.
	if (reference ~= tes3.getPlayerRef()) then
		return false
	end

	-- We only care about alchemy items.
	if (potion.objectType ~= tes3.objectType.alchemy) then
		return false
	end

	-- We only care if the potion is self-targetting.
	if (this.isPotionSelfTargeting(potion) == false) then
		return false
	end

	-- Make sure we weren't told to ignore the next event.
	if (interop.skipNextConsumptionCheck) then
		interop.skipNextConsumptionCheck = false
		return false
	end

	return true
end

return this