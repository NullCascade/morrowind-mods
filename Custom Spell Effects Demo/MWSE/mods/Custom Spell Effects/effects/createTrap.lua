
--[[
	Custom Spell Effects Demonstration

	This effect lets a player place another spell onto a door/container.
]]

local common = require("Custom Spell Effects.common")

tes3.claimSpellEffectId("createTrap", 200)

local lastCastAtReference = nil

-- Checks to see if a spell has at least one effect that is not self-targeting.
local function spellHasValidRange(spell)
	for _, effect in ipairs(spell.effects) do
		if (effect.id ~= -1) then
			if (effect.rangeType ~= tes3.effectRange.self) then
				return true
			end
		end
	end
	return false
end

-- Consumes a spell being cast, if we're currently waiting for one to put on a trap.
local function checkForNextSpellCast(e)
	if (lastCastAtReference == nil or e.caster ~= tes3.player) then
		return
	end

	-- Make the spell fail, as it's consumed by Create Trap.
	local target = lastCastAtReference
	e.castChance = 0
	lastCastAtReference = nil

	-- Make sure the spell is valid. Has to be a touch spell.
	if (e.source.castType ~= tes3.spellType.spell) then
		tes3.messageBox("Create Trap failed! Only spells can be imbued.")
		return
	elseif (not spellHasValidRange(e.source)) then
		tes3.messageBox("Create Trap failed! Self-aimed spells do not make for good traps.")
		return
	end

	-- All good? Set the trap.
	tes3.setTrap({ reference = target, spell = e.source })
	lastCastAtReference = nil

	-- Hacky workaround to replace the "spell failed" message with our custom message.
	local gmst = tes3.findGMST(tes3.gmst.sMagicSkillFail)
	local oldValue = gmst.value
	gmst.value = string.format("%s is now trapped using %s.", target.object.name, e.source.name)
	timer.delayOneFrame(function() gmst.value = oldValue end, timer.real)
end
event.register("spellCast", checkForNextSpellCast)

local function onSpellEffectTick(e)
	-- Trigger into the spell system.
	if (not e:trigger()) then
		return
	end

	-- We only care about the spell when it is finally ending. Ignore all other frames.
	if (e.sourceInstance.state ~= tes3.spellState.ending) then
		return
	end

	-- Get the player's target.
	local target = tes3.getPlayerTarget()
	if (target == nil) then
		return
	elseif (target.object.objectType ~= tes3.objectType.container and target.object.objectType ~= tes3.objectType.door) then
		tes3.messageBox("The object resists your spell.")
		return
	end

	-- Is the thing already trapped?
	if (tes3.getTrap({ reference = target })) then
		tes3.messageBox("The object resists your spell.")
		return
	end

	-- Mark our reference as ready for imbuing.
	tes3.messageBox("%s is ready for trapping.", target.object.name)
	lastCastAtReference = target
end

local function addCustomMagicEffect()
	tes3.addMagicEffect({
		-- Base information.
		id = tes3.effect.createTrap,
		name = "Prepare Magic Trap",
		description = "This effect allows the placement of another spell onto a door or container. After casting the spell, cast a second spell at the object to imbue it with that spell as a trap.",
		school = tes3.magicSchool.alteration,

		-- Basic dials.
		baseCost = 50.0,
		speed = 1,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = false,
		appliesOnce = true,
		canCastSelf = true,
		canCastTarget = false,
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
		icon = "s\\tx_s_create_trap.tga",
		particleTexture = "vfx_ill_glow.tga",
		castSound = "alteration cast",
		castVFX = "VFX_AlterationCast",
		boltSound = "alteration bolt",
		boltVFX = "VFX_AlterationBolt",
		hitSound = "alteration hit",
		hitVFX = "VFX_AlterationHit",
		areaSound = "alteration area",
		areaVFX = "VFX_AlterationArea",
		lighting = { 193 / 255, 100 / 255, 249 / 255 },
		size = 1,
		sizeCap = 50,

		-- Required callbacks.
		onTick = onSpellEffectTick,
	})
end
event.register("magicEffectsResolved", addCustomMagicEffect)

local function addTestSpells()
	common.addTestSpell({
		id = "nc_CreateTrap",
		name = "Imbue Trap",
		effect = tes3.effect.createTrap,
		range = tes3.effectRange.self,
	})
end
event.register("loaded", addTestSpells)
