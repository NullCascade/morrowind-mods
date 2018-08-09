--[[

	This is a proof of concept of how to provide DLL-style extensions to Morrowind.
	We do this by using LuaJIT's FFI to connect to a precompiled DLL file.

	In this example we will be interfacing with Discord's Rich Presence API to
	show the player's name, race, class, level, and current location to people who
	click on the user's name in Discord.

	The interface to the discord-rpc.dll library is pfirsich's MIT-licensed
	lua-discord-RPC libary, which comes bundled with this download. Visit his
	project here: https://github.com/pfirsich/lua-discordRPC

--]]

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180725) then
	mwse.log("[Discord Rich Presence] Build date of %s does not meet minimum build date of 20180725.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/discord/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/discord/", true)) then
		mwse.log("[Discord Rich Presence] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Discord Rich Presence] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/discord' and restart Morrowind.")
		return
	end
end

local discordRPC = require("Discord Rich Presence.discordRPC")

-- Table where we store data that is going to get sent to Discord.
local presenceData = {
	details = "In main menu",
	largeImageKey = "default",
	startTimestamp = os.time(os.date("*t")),
}

-- This function updates the presenceData table with new information.
local function updateGameData()
	if (tes3.player == nil) then
		return
	end

	-- Set the details to the player's name/class/level.
	local playerObject = tes3.player.object
	presenceData.details = string.format( "%s (%s, %s %d)", playerObject.name, playerObject.race.name, playerObject.class.name, playerObject.level )

	-- Set the state to the player cell.
	local playerCell = tes3.getPlayerCell()
	if (playerCell) then
		presenceData.state = playerCell.id
	else
		presenceData.state = "Exploring the unknown!"
	end
end

-- Updates the information used with Discord, and pushes it to Discord.
local function pushUpdatedData()
	-- Update game information. 
	updateGameData()

	-- Fire off an event in case another mod wants to mess with this and change anything.
	event.trigger("discordUpdate", presenceData)

	-- Fire it off to Discord.
	discordRPC.updatePresence(presenceData)
end

-- When the game is first initialized we want to also initialize the RPC module.
local function onInitialized()
	-- Initialize the RPC module.
	discordRPC.initialize("428347126184017920", true)
end
event.register("initialized", onInitialized)

-- When the game loads, we want to ensure that we start timers to keep updating Discord.
local function onLoaded()
	pushUpdatedData()
	timer.start(30, pushUpdatedData, 0)
end
event.register("loaded", onLoaded)

-- Discord callback for when it is ready.
function discordRPC.ready()
	print("[Discord Rich Presence]: Discord ready.")

	-- When Discord first reports that it is ready, update presence. We very likely
	-- won't have interesting data at this point.
	discordRPC.updatePresence(presenceData)
	
	-- Every frame, we want to ensure that any discord callbacks are run.
	event.register("enterFrame", discordRPC.runCallbacks)
end

-- Discord callback for when we are disconnected.
function discordRPC.disconnected(errorCode, message)
    print(string.format("[Discord Rich Presence]: Discord disconnected (%d: %s)", errorCode, message))
end

-- Discord callback for any errors.
function discordRPC.errored(errorCode, message)
    print(string.format("[Discord Rich Presence]: Discord error (%d: %s)", errorCode, message))
end
