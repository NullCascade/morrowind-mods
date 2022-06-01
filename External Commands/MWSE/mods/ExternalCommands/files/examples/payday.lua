
--
-- This example adds 100 gold to the player's inventory.
-- Any item can be added this way.
--

-- Our parameters that we want to use. These can be easily changed.
local itemToAdd = "gold_100"
local countToAdd = 100

-- Our actual script logic. Add a number of an item to the player.
tes3.addItem({
	reference = tes3.player,
	item = itemToAdd,
	count = countToAdd,
	playSound = true,
})
