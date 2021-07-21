--[[
	Mod Initialization: Easy Escort
	Author: NullCascade

	Ensures that your followers get warped to you if they get too far away. Compatible with any
	follower from any mod, without any special script attached to that NPC.

]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180726) then
	mwse.log("[Easy Escort] Build date of %s does not meet minimum build date of 20180726.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/escort/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/escort/", true)) then
		mwse.log("[Easy Escort] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Easy Escort] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/escort' and restart Morrowind.")
		return
	end
end

local config = require("Easy Escort.config")

-- Make blacklist consistent.
if (config.blacklist) then
	for _, id in ipairs(config.blacklist) do
		config.ignoreList[id:lower()] = true
	end
	config.blacklist = nil
end
if (config.blackList) then
	for _, id in ipairs(config.blackList) do
		config.ignoreList[id:lower()] = true
	end
	config.blackList = nil
end

-- Ensure any user-added IDs are also lowercased.
do
	local addDict = {}
	local removeList = {}
	for id, value in ipairs(config.ignoreList) do
		local lowerId = id:lower()
		if (id ~= lowerId) then
			table.insert(removeList, id)
			addDict[lowerId] = value
		end
	end

	for id, value in pairs(addDict) do
		config.ignoreList[id] = value
	end

	for _, id in ipairs(removeList) do
		config.ignoreList[id] = nil
	end
end

-- Determines if an id is in the blacklist.
local function isInBlacklist(id)
	return config.ignoreList[id]
end

-- Determines if an actor is in the blacklist.
local function isActorInBlackList(actor)
	local reference = actor.reference

	-- Is it not in our blacklist?
	return isInBlacklist(reference.baseObject.id:lower())
end

-- Determines if an actor is a valid companion.
local function validCompanionCheck(actor)
	local macp = tes3.mobilePlayer

	-- The player shouldn't count as his own companion.
	if (actor == tes3.mobilePlayer) then
		return false
	end

	-- Restrict based on AI package type.
	local allowedPackages = { [tes3.aiPackage.none] = true, [tes3.aiPackage.follow] = true }
	if (not allowedPackages[tes3.getCurrentAIPackageId({ reference = actor })]) then
		return false
	end

	-- Respect the blacklist.
	if (isActorInBlackList(actor)) then
		return false
	end

	-- Make sure we don't teleport dead actors.
	local animState = actor.actionData.animationAttackState
	if (actor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end

	-- Don't teleport companions underwater if they can't breathe underwater.
	if (macp.isFlying and not actor.isFlying) then
		return false
	end

	-- Don't teleport companions above the ground if they can't fly.
	if (macp.isUnderwater and not actor.waterBreathing > 0) then
		return false
	end

	return true
end

-- Repositions any followers that don't share a cell with the player.
local function forceFollowFriendlyActors()
	local currentCell = tes3.getPlayerCell()

	local positionParams = { cell = currentCell, position = tes3.player.position, orientation = tes3.player.orientation }

	for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
		if (validCompanionCheck(actor)) then
			local reference = actor.reference
			positionParams.reference = reference
			if (currentCell.isInterior) then
				if (reference.cell ~= currentCell or reference.position:distance(tes3.player.position) > config.followDistance) then
					tes3.positionCell(positionParams)
				else
				end
			else
				if (reference.position:distance(tes3.player.position) > config.followDistance) then
					tes3.positionCell(positionParams)
				else
				end
			end
		end
	end
end
event.register("cellChanged", function(e)
	timer.delayOneFrame(forceFollowFriendlyActors)
end)

-- 
-- Initialize interop library to support modifying the blacklist.
-- 

local interop = require("Easy Escort.interop")

function interop.addToBlacklist(id)
	config.ignoreList[id:lower()] = true
end

function interop.removeFromBlacklist(id)
	config.ignoreList[id:lower()] = nil
end

interop.blackListContains = isInBlacklist

interop.validCompanionCheck = validCompanionCheck

-- 
-- Set up Mod Config Menu support.
-- 

local modConfig = require("Easy Escort.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Easy Escort", modConfig)
end
event.register("modConfigReady", registerModConfig)
