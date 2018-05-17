local this = {}

-- Basic module description.
this.name = "Oblivion Style"
this.description = "Prevents more than 4 potions from being active at once."

-- Counter of currently consumed alchemy items.
local potionCounter = 0

-- Decrease potion count by one.
local decrementCounter = function()
	potionCounter = potionCounter - 1
	if (potionCounter < 0) then
		potionCounter = 0
	end
end

function isPotionSelfTargeting(potion)
	for i = 1, #potion.effects do
		local effect = potion.effects[i]
		if (effect.rangeType ~= effect.rangeType.self) then
			return false
		end
	end
	
	return true
end

function this.onEquip(e)
	-- We only care about alchemy items.
	local potion = e.item
	if (potion.objectType ~= tes3.objectType.alchemy) then
		return
	end

	-- We only care if the potion is self-targetting.
	if (isPotionSelfTargeting(potion) == false) then
		return
	end

	-- Do we have more than 4 alchemy items imbibed already?
	if (potionCounter >= 4) then
		tes3.messageBox({ message = "Only 4 potions can be imbibed at a time." })
		return false
	end

	-- Increase the potion counter.
	potionCounter = potionCounter + 1

	-- Find the longest duration used.
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

	-- When the potion would expire, reduce the counter again.
	timer.start(duration, decrementCounter)
end

-- Called when the module has been selected and loaded by mod_init.
function this.onInitialized()
	event.register("equip", this.onEquip)
end

return this