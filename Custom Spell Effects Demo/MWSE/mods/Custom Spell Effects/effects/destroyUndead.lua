
--[[
	Custom Spell Effects Demonstration

	This effect lets a player place another spell onto a door/container.
]]

local common = require("Custom Spell Effects.common")

tes3.claimSpellEffectId("damageUndead", 202)

local effectObject = nil

-- Make sure that only undead are affected.
local function resistEffect(e)
	local reference = e.effectInstance.target
	local mobile = reference.mobile
	if (mobile.actorType ~= tes3.actorType.creature or reference.baseObject.type ~= tes3.creatureType.undead) then
		return true
	end

	return false
end

local function onSpellEffectTick(e)
	-- Get the target's mobile actor.
	local mobile = e.effectInstance.target.mobile

	-- Trigger the modification to the statistic through the event system.
	e:trigger({
		value = mobile.health,
		type = tes3.effectEventType.modStatistic,
		negateOnExpiry = false,
		resistanceCheck = resistEffect,
	})
end

local function addCustomMagicEffect()
	effectObject = tes3.addMagicEffect({
		-- Base information.
		id = tes3.effect.damageUndead,
		name = "Damage Undead",
		description = "It's like fire damage, only more efficient, and limited to undead. Make a more interesting description.",
		school = tes3.magicSchool.restoration,

		-- Basic dials.
		baseCost = 3.5,
		speed = 1.25,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = false,
		canCastSelf = true,
		canCastTarget = true,
		canCastTouch = true,
		casterLinked = false,
		hasContinuousVFX = true,
		hasNoDuration = false,
		hasNoMagnitude = false,
		illegalDaedra = false,
		isHarmful = true,
		nonRecastable = false,
		targetsAttributes = false,
		targetsSkills = false,
		unreflectable = false,
		usesNegativeLighting = false,

		-- Graphics/sounds.
		icon = "s\\tx_s_rstor_health.tga",
		particleTexture = "vfx_bluecloud.tga",
		castSound = "restoration cast",
		castVFX = "VFX_RestorationCast",
		boltSound = "restoration bolt",
		boltVFX = "VFX_RestoreBolt",
		hitSound = "restoration hit",
		hitVFX = "VFX_RestorationHit",
		areaSound = "restoration area",
		areaVFX = "VFX_RestorationArea",
		lighting = { 255 / 255, 255 / 255, 255 / 255 },
		size = 1,
		sizeCap = 50,

		-- Required callbacks.
		onTick = onSpellEffectTick,
	})
end
event.register("magicEffectsResolved", addCustomMagicEffect)

local function addTestSpells()
	common.addTestSpell({
		id = "nc_DamageUndead",
		name = "Damage Undead",
		effect = tes3.effect.damageUndead,
		range = tes3.effectRange.target,
		min = 5,
		max = 5,
		duration = 3,
	})
end
event.register("loaded", addTestSpells)
