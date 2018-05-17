
--[[
	Mod Initialization: Dead is Dead
	Author: NullCascade



]]--

-- The name of the config file to use in the MWSE directory.
local configFilename = "nc_death_data"

-- Get the mod-specific config saved to the player's save game.
local function getModSaveConfig()
	local playerData = tes3.getPlayerRef().data
	if (playerData.nc == nil) then
		playerData.nc = {}
	end
	if (playerData.nc.death == nil) then
		playerData.nc.death = {}
	end

	return playerData.nc.death
end

-- Get the config file contents, or default structure.
local function getModSavelessConfig()
	local config = json.loadfile(configFilename)
	if (config == nil) then
		config = { characters = {} }
	end
	return config
end

-- Gets the character id. Beware that this is stored as a string because it's a key in json, then might get
-- converted to a number. We'll force it back to a string in this function.
local function getCharacterId()
	local config = getModSaveConfig()
	if (config.id == nil) then
		config.id = os.time(os.date("!*t"))
		print("[nc-death] Generating new character ID: " .. config.id)
	else
		print("[nc-death] Recognized character: " .. config.id)
	end
	return tostring(config.id)
end

-- Inserts a new character into the config file, with a given number of lives.
local function addCharacterToSavelessConfig(lives)
	local config = getModSavelessConfig()
	local id = getCharacterId()
	config.characters[id] = {
		lives = lives,
		deaths = 0,
	}
	json.savefile(configFilename, config)
end

-- Increments the death counter for the current character.
local function incrementDeathCount()
	local config = getModSavelessConfig()
	local id = getCharacterId()

	local deaths = config.characters[id].deaths + 1
	config.characters[id].deaths = deaths

	json.savefile(configFilename, config)
	return deaths, config.characters[id].lives
end

-- Returns the current number of deaths and lives.
local function getDeathCount()
	local config = getModSavelessConfig()
	local id = getCharacterId()
	return config.characters[id].deaths or 0, config.characters[id].lives or 1
end

-- Temporary variable for configuring how many lives a character will get.
local configLifeCount = 1

-- Forward declaration of menus, so that they can be traversed through more sanely.
local configMainMenu
local configLifeCountMenu
local configNewCharacterMenu

-- Configuration menu: life count
configLifeCountMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then -- -1 life
			if (configLifeCount > 1) then
				configLifeCount = configLifeCount - 1
			end
		elseif (e.button == 2) then -- +1 life
			configLifeCount = configLifeCount + 1
		else -- Unhandled button. Go back to the main menu.
			configMainMenu()
			return;
		end
	end

	tes3.messageBox({
		message = "Number of lives this character will have: " .. configLifeCount,
		buttons = { "-", "Back", "+" },
		callback = configLifeCountMenu
	})
end

-- Main configuration menu
configMainMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then
			configLifeCountMenu()
		elseif (e.button == 1) then
			local config = getModSaveConfig()
			config.enabled = true
			addCharacterToSavelessConfig(configLifeCount)
			tes3.messageBox({ message = "Permadeath enabled. Good luck!" })
			print("[nc-death] Permadeath enabled.")
		end
		return
	end

	tes3.messageBox({
		message = "Will this character use permadeath?",
		buttons = { "Change Life Count", "Yes", "No" },
		callback = configMainMenu,
	})
end

-- Checks to see if the character has run out of lives, and starts a new game if they run out.
local function checkPermadeath()
	local deaths, lives = getDeathCount()
	local livesLeft = lives - deaths
	if (livesLeft > 0) then
		local message = "This character has " .. livesLeft .. " lives left."
		if (livesLeft == 1) then
			message = "There is only one life. Live it well."
		end
		tes3.messageBox({ message = message })
		return
	end

	timer.start(1, function()
		tes3.messageBox({
			message = "This character's story has come to an end.",
			buttons = { "Bummer" },
			callback = tes3.newGame
		})
	end)
end

-- Keep track if the player has died already this session, so we don't double up on damaged events.
local diedThisSession = false

-- Loaded event. We'll check to see if new games want permadeath, or see how many lives the player has left.
local function onLoaded(e)
	if (e.newGame == true) then
		-- Delay for 8 seconds to give Juib a moment.
		-- TODO: Check with other alternate start mods. They won't break the mod,                            
		-- but they might make it awkward.
		timer.start(8, configMainMenu)
	elseif (getModSaveConfig().enabled == true) then
		checkPermadeath()
	end

	diedThisSession = false
end
event.register("loaded", onLoaded)

-- Damaged event. Increment the death counter if the player has died.
local function onDamaged(e)
	-- We only care about player damage.
	if (e.mobile ~= tes3.getMobilePlayer()) then
		return
	end

	if (diedThisSession == false and e.mobile.health.current <= 0) then
		print("[nc-death] The player has died!")
		incrementDeathCount()
		diedThisSession = true
	end
end
event.register("damaged", onDamaged)
