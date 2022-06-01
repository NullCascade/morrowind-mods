
--
-- This example shows how to apply a spell or potion to the player.
--

-- Our parameters that we want to use. These can be easily changed.
local spellOrPotionId = "Wild Levitate"

-- Our actual script logic. Apply the chosen spell or potion ID to the player.
tes3.applyMagicSource({
	reference = tes3.player,
	source = spellOrPotionId,
	bypassResistances = false,
})
