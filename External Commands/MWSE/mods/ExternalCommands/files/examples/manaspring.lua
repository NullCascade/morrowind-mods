
--
-- This example shows how to apply arbitrary effects to the player.
-- We will be giving him 1/s magicka regeneration for 60 seconds.
--

local tooltipName = "Manaspring"

-- The effects to add. There are some requirements here:
-- 1) Only 8 effects can be defined.
-- 2) The table formatting matters. Make sure you don't have
local effects = {}

-- Add our first (and only) effect. Simple restore magicka.
table.insert(effects, {
	id = tes3.effect.restoreMagicka,
	duration = 60,
	min = 1,
	max = 1,
})

-- Our actual script logic. Apply our chosen effects to the player.
tes3.applyMagicSource({
	reference = tes3.player,
	name = tooltipName,
	effects = effects,
	bypassResistances = false,
})
