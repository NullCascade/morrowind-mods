
--[[
	Custom Spell Effects Demonstration

	This effect lets a player place another spell onto a door/container.
]]

local common = require("Custom Spell Effects.common")

tes3.claimSpellEffectId("blink", 201)

local function onSpellEffectCollision(e)
	local caster = e.sourceInstance.caster
	tes3.positionCell({ reference = caster, position = e.collision.point, cell = caster.cell })
end

local function addCustomMagicEffect()
	tes3.addMagicEffect({
		-- Base information.
		id = tes3.effect.blink,
		name = "Blink",
		description = "This effect allows the subject to instantly transport to the point that the spell collides with another surface.",
		school = tes3.magicSchool.mysticism,

		-- Basic dials.
		baseCost = 150.0,
		speed = 1,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = false,
		appliesOnce = true,
		canCastSelf = false,
		canCastTarget = true,
		canCastTouch = false,
		casterLinked = false,
		hasContinuousVFX = false,
		hasNoDuration = true,
		hasNoMagnitude = true,
		illegalDaedra = false,
		isHarmful = false,
		nonRecastable = false,
		targetsAttributes = false,
		targetsSkills = false,
		unreflectable = false,
		usesNegativeLighting = false,

		-- Graphics/sounds.
		icon = "s\\tx_s_blink.tga",
		particleTexture = "vfx_particle064.tga",
		castSound = "mysticism cast",
		castVFX = "VFX_MysticismCast",
		boltSound = "mysticism bolt",
		boltVFX = "VFX_MysticismBolt",
		hitSound = "mysticism hit",
		hitVFX = "VFX_MysticismHit",
		areaSound = "mysticism area",
		areaVFX = "VFX_MysticismArea",
		lighting = { 206 / 255, 237 / 255, 255 / 255 },
		size = 1,
		sizeCap = 50,

		-- Required callbacks.
		onCollision = onSpellEffectCollision,
	})
end
event.register("magicEffectsResolved", addCustomMagicEffect)

local function addTestSpells()
	common.addTestSpell({
		id = "nc_Blink",
		name = "Blink",
		effect = tes3.effect.blink,
		range = tes3.effectRange.target,
	})
end
event.register("loaded", addTestSpells)
