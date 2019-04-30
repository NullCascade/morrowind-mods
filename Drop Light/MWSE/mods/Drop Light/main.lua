
local twoHandedWeapons = {
	[tes3.weaponType.longBladeTwoClose] = true,
	[tes3.weaponType.bluntTwoClose] = true,
	[tes3.weaponType.bluntTwoWide] = true,
	[tes3.weaponType.spearTwoWide] = true,
	[tes3.weaponType.axeTwoHand] = true,
	[tes3.weaponType.marksmanBow] = true,
	[tes3.weaponType.marksmanCrossbow] = true,
}

local function usesOffHandSlot(item)
	local itemType = item.objectType
	if (itemType == tes3.objectType.weapon) then
		return twoHandedWeapons[item.type] == true
	elseif (itemType == tes3.objectType.armor) then
		return item.slot == tes3.armorSlot.shield
	end

	return false
end

local function onEquip(e)
	-- We only care about the player.
	if (e.reference ~= tes3.player) then
		return
	end

	-- We only do this if the player is in combat.
	if (not tes3.mobilePlayer.inCombat) then
		return
	end

	-- Is the player equipping a two handed or off-hand item?
	if (not usesOffHandSlot(e.item)) then
		return
	end

	-- Does the player have a light equipped?
	local equippedLight = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.light })
	if (equippedLight == nil) then
		return
	end

	-- Don't bother with lights that are off by default.
	if (equippedLight.object.isOffByDefault) then
		return
	end

	-- Delay dropping the item by a frame to prevent the equipped item from being duplicated.
	-- Cache the light vars. The equipped stack will no longer be valid after a frame.
	local light = equippedLight.object
	local lightVars = equippedLight.variables
	timer.delayOneFrame(function()
		tes3.dropItem({ reference = tes3.mobilePlayer, item = light, itemData = lightVars })
	end, timer.real)
end
event.register("equip", onEquip)
