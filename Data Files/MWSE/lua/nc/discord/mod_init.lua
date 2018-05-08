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

local discordRPC = require("nc.discord.discordRPC")

-- Table where we store data that is going to get sent to Discord.
local presenceData = {
	details = "In main menu",
	largeImageKey = "default",
	startTimestamp = os.time(os.date("*t")),
}

-- This function updates the presenceData table with new information.
local function updateGameData()
	local playerRef = tes3.getPlayerRef()
	if (playerRef == nil) then
		return
	end

	-- Set the details to the player's name/class/level.
	local player = playerRef.object
	presenceData.details = string.format( "%s (%s, %s %d)", player.name, player.race.name, player.class.name, player.level )

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
	print("[discord_rpc]: Discord ready.")

	-- When Discord first reports that it is ready, update presence. We very likely
	-- won't have interesting data at this point.
	discordRPC.updatePresence(presenceData)
	
	-- Every frame, we want to ensure that any discord callbacks are run.
	event.register("enterFrame", discordRPC.runCallbacks)
end

-- Discord callback for when we are disconnected.
function discordRPC.disconnected(errorCode, message)
    print(string.format("[discord_rpc]: Discord disconnected (%d: %s)", errorCode, message))
end

-- Discord callback for any errors.
function discordRPC.errored(errorCode, message)
    print(string.format("[discord_rpc]: Discord error (%d: %s)", errorCode, message))
end
