
local config = require("Smarter Strike Sounds.config")

--- @type tes3enchantment
local lastEnchantment = nil

--- Get the sound to play for a given enchantment's failure.
--- @param enchantment tes3enchantment
--- @return tes3sound?
local function getMagicCastFailureSound(enchantment)
	-- Get a list of the available sounds.
	local enchantmentSounds = {}
	for _, effect in ipairs(enchantment.effects) do
		local magicEffect = effect.object
		if (magicEffect) then
			table.insert(enchantmentSounds, magicEffect.spellFailureSoundEffect)
		end
	end

	-- Choose our enchant failure sound.
	local enchantFailureSound = config.playRandomEffectSound and table.choice(enchantmentSounds) or enchantmentSounds[1]

	-- From here we only change behavior for on-strike enchants.
	if (enchantment.castType ~= tes3.enchantmentType.onStrike) then
		return enchantFailureSound
	end

	-- Don't repeat sounds.
	if (config.doNotRepeatStrikeSounds and lastEnchantment == enchantment) then
		return
	end
	lastEnchantment = enchantment

	return enchantFailureSound
end

-- Create our MCM.
dofile("Smarter Strike Sounds.mcm")

--[[
Before:
	00515203 0E4                 movsx   edx, [eax+TES3::Enchantment.effects[0].magicEffectID]
	00515207 0E4                 mov     ecx, dataHandler
	0051520D 0E4                 mov     ecx, [ecx]
	0051520F 0E4                 push    edx
	00515210 0E8                 call    TES3::DataHandler::getMagicEffectData(int)
	00515215 0E4                 mov     ecx, eax
	00515217 0E4                 call    TES3::MagicEffectData::getMagicCastFailureSound()

After:
	00515203 0E4                 nop
	...
	00515214 0E4                 nop
	00515215 0E4                 mov     ecx, eax
	00515217 0E4                 call    lua::getMagicCastFailureSound
--]]
mwse.memory.writeNoOperation({ address = 0x515203, length = 0x515215 - 0x515203 })
mwse.memory.writeFunctionCall({
	address = 0x515217,
	call = getMagicCastFailureSound,
	previousCall = 0x4A9F00,
	signature = {
		this = "tes3object",
		returns = "tes3object",
	},
})
