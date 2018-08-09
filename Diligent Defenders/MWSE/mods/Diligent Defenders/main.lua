
--[[
	Mod Initialization: Diligent Defenders
	Author: NullCascade

	This module makes it so that when the player or the player's companions are attacked, any companions
	will launch into action in defense.

]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180725) then
	mwse.log("[Diligent Defenders] Build date of %s does not meet minimum build date of 20180725.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/defenders/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/defenders/", true)) then
		mwse.log("[Diligent Defenders] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Diligent Defenders] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/consume' and restart Morrowind.")
		return
	end
end

local config = mwse.loadConfig("Diligent Defenders")
if (config == nil) then
	config = { blacklist = {} }
end

-- Package to send to the mod config.
local modConfig = require("Diligent Defenders.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Diligent Defenders", modConfig)
end
event.register("modConfigReady", registerModConfig)

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
	local macp = tes3.mobilePlayer
	for actor in tes3.iterate(macp.friendlyActors) do
		-- If the companion doesn't currently have a target, isn't the player, and isn't in a blacklist, start combat.
		if (actor.actionData.target == nil and actor ~= macp and not inBlackList(actor)) then
			mwscript.startCombat({ reference = actor.reference, target = e.actor.reference })
		end
	end
end
event.register("combatStarted", onCombatStart)
