local this = {}

-- Basic module description.
this.name = "Vanilla NPC Style"
this.description = "Allows 1 potion to be consumed every 5 seconds."

-- Counter of currently consumed alchemy items.
local potionActive = false

-- Decrease potion count by one.
local clearConsumptionFlag = function()
	potionActive = false
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
	if (potionActive) then
		tes3.messageBox({ message = "You must wait 5 seconds between drinking potions." })
		return false
	end

	-- Increase the potion counter.
	potionActive = true

	-- After 5 seconds, reset the flag.
	timer.start(5, clearConsumptionFlag)
end

-- Called when the module has been selected and loaded by mod_init.
function this.onInitialized()
	event.register("equip", this.onEquip)
end

return this