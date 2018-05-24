local this = {}

local shared = require("nc.consume.shared")

-- Basic module description.
this.name = "Vanilla NPC Style"
this.description = "Allows 1 potion to be consumed every 5 seconds."

-- Counter of currently consumed alchemy items.
local potionActive = false

-- Decrease potion count by one.
local clearConsumptionFlag = function()
	potionActive = false
end

function this.onEquip(e)
	-- Make some basic checks (player equipping, it's a potion, etc).
	if (not shared.basicPotionChecks(e)) then
		return
	end

	-- Do we already have a potion active?
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