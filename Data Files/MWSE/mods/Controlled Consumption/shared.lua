local interop = require("Controlled Consumption.interop")

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

function this.getLongestPotionDuration(potion)
	local duration = 0
	for i = 1, #potion.effects do
		-- Get and validate effect.
		local effect = potion.effects[i]
		if (effect.id < 0) then
			break
		end

		-- Check to see if this was a longer lasting effect.
		if (effect.duration > duration) then
			duration = effect.duration
		end
	end

	-- 0-length potions count as 1 second.
	if (duration <= 0) then
		duration = 1
	end

	return duration
end

function this.getPersistentData()
	if (tes3.player == nil) then
		return nil
	end

	local data = tes3.player.data
	if (not data.nc) then
		data.nc = { consume = {} }
	elseif (not data.nc.consume) then
		data.nc.consume = {}
	end
	return data
end

return this