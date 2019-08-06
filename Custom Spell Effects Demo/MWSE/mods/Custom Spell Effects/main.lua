
--[[
	Ideas to implement:
		- Banish Daedra: Unsummons a daedra up to a given level.
		x Blink: Projectile-based teleportation.
		- Change Weather: Sets the weather to something new.
		- Contingency: Set another spell to be cast when a certain condition is met.
		- Create rune: Like a trap, but spawns a new placeable that releases another spell when triggered.
		x Create trap: Put a previously cast spell onto a door/container.
		- Destroy Undead: Damage spell. Only targets undead.
		- Release Soul: Select a soul gem. Release the creature inside of it.
		- Repair Equipment: Repairs a piece of equipment a bit.
		- Simple custom bound armor: Need to fix shit so that the drop behavior is consistent.
		- Simple custom bound weapon: Need to fix shit so that the drop behavior is consistent.
		- Simple custom summon: Does it work on NPCs?
		- Slow time: Bullet time!
		- Soul Cloak: Auto-soultrap on anything that dies nearby.
		- Temporary Lycanthrope: Temporarily become a werewolf.
		- Trigger Bloodmoon: Causes the moon to become a bloodmoon for a short time.
]]

-- Create our spells.
dofile("Data Files/MWSE/mods/Custom Spell Effects/effects/blink.lua")
dofile("Data Files/MWSE/mods/Custom Spell Effects/effects/createTrap.lua")
