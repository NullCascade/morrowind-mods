
--
-- This example makes the player drop their weapon.
--

-- First find the weapon.
local playerWeaponStack = tes3.mobilePlayer.readiedWeapon
if (not playerWeaponStack) then
	tes3.messageBox("Someone tried to make you drop your weapon, but you outsmarted them!")
	return
end

-- Call the relevant function.
tes3.dropItem({
	reference = tes3.player,
	item = playerWeaponStack.object,
	itemData = playerWeaponStack.itemData,
})
