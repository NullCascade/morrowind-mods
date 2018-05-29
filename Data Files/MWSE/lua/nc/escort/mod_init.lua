
--[[
	Mod Initialization: Easy Escort
	Author: NullCascade

	Ensures that your followers get warped to you if they get too far away. Compatible with any
	follower from any mod, without any special script attached to that NPC.

]]--

local config = json.loadfile("nc_escort_config")

local function inBlackList(actor)
	local reference = actor.reference

	-- Get the ID. If we're looking at an instance, check against the base object instead.
	local id = reference.id
	if (reference.object.isInstance) then
		id = reference.object.baseObject.id
	end

	-- Is it not in our blacklist?
	if (table.find(config.blackList, id) ~= nil) then
		return true
	end

	-- We found it in the blacklist table above.
	return false
end

local function forceFollowFriendlyActors(e)
	local playerMobile = tes3.getMobilePlayer()
	local currentCell = tes3.getPlayerCell()

	local positionParams = {
		cell = currentCell.id,
		x = playerMobile.position.x,
		y = playerMobile.position.y,
		z = playerMobile.position.z
	}

	for actor in tes3.iterate(playerMobile.friendlyActors) do
		if (actor ~= playerMobile and not inBlackList(actor)) then
			local reference = actor.reference
			if (reference.cell ~= currentCell or reference.position:distance(playerMobile.position) > config.followDistance) then
				positionParams.reference = reference
				mwscript.positionCell(positionParams)
			end
		end
	end
end

local function onLoaded(e)
	timer.start(config.pollRate, forceFollowFriendlyActors, 0)
end

if (config ~= nil) then
	mwse.log("[nc-follow] Loaded config:\n%s", json.encode(config, { indent = true }))
	event.register("loaded", onLoaded)
	event.register("cellChanged", forceFollowFriendlyActors)
else
	mwse.log("[nc-follow] ERROR: Could not load config file! Was installation done right?")
end
