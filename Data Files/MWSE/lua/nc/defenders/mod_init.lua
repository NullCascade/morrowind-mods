
--[[
	Mod Initialization: Diligent Defenders
	Author: NullCascade

	This module makes it so that when the player or the player's companions are attacked, any companions
	will launch into action in defense.

]]--

local config = json.loadfile("nc_defenders_config")

-- Check to see if the companion is in a blacklist.
local function inBlackList(actor)
	local reference = actor.reference

	-- Get the ID. If we're looking at an instance, check against the base object instead.
	local id = reference.id
	if (reference.object.isInstance) then
		id = reference.object.baseObject.id
	end

	-- Is it in our blacklist?
	if (table.find(config.blackList, id) ~= nil) then
		return true
	end

	-- We didn't find it in the blacklist table above.
	return false
end

-- Checks to see if the mobile actor is one of the player's companions.
local function isPlayerCompanion(target)
	local playerMobile = tes3.getMobilePlayer()
	for actor in tes3.iterate(playerMobile.friendlyActors) do
		if (actor == target) then
			return true
		end
	end
	return false
end

-- Whenever combat starts, see if it is with the player or one of his companions. If it is, launch the companions into action.
local function onCombatStart(e)
	-- We only care if a companion (which includes the player) is entering combat.
	if (not isPlayerCompanion(e.target)) then
		return
	end

	-- Loop through player companions.
	local playerMobile = tes3.getMobilePlayer()
	for actor in tes3.iterate(playerMobile.friendlyActors) do
		-- If the companion doesn't currently have a target, isn't the player, and isn't in a blacklist, start combat.
		if (actor.actionData.target == nil and actor ~= playerMobile and not inBlackList(actor)) then
			mwscript.startCombat({ reference = actor.reference, target = e.actor.reference })
		end
	end
end
event.register("combatStarted", onCombatStart)
