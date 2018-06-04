
--[[
	Mod Initialization: MWSE Sophisticated Save System
	Author: NullCascade

	This mod is responsible for changing how saves are done in Morrowind.

	Features:
		* Overrides autosaves and quicksaves to keep a variable amount of rotating
		  saves.
		* Autosaves the game every 10 minutes. The time between saves is customizable.
		* Overrides the quickload behavior to load the newest save, instead of the
		  quicksave specifically. This can be changed to only load the newest quicksave,
		  which is closer to vanilla behavior.
		* A hard save that will not be deleted can be created by with Alt+<QuickSave>
		* The mod can be configured by using Alt+Shift+<QuickSave>
]]--

local lfs = require("lfs")

-- Default configuration values.
local defaultConfig = {
	timeBetweenAutoSaves = 10,
	minimumTimeBetweenAutoSaves = 1,
	maxSaveCount = 10,
	loadLatestSave = true,
	saveOnTimer = true,
	saveOnCombatStart = true,
	saveOnCombatEnd = true,
	saveOnCellChange = true,
}

-- Configuration table.
local config = table.copy(defaultConfig)

-- The last timestamp that an autosave was done on. We use this to prevent saves from happening too frequently.
local lastAutoSaveTimestamp = 0

-- Our config menus need to be forward declared so they can be moved between cleanly.
local configShowEnableDisableFeatureMenu
local configShowConfigSaveCountMenu
local configShowConfigTimerMenu
local configShowConfigMinimumTimerMenu
local configShowMainMenu

-- Generates a save name with a keyed meaning. These meanings are:
--  a: Autosave, either by the usual resting or from an event.
--  q: Quicksave, with the usual hotkey.
--  f: Forced save, created with Alt+Quicksave.
local function getSaveName(key, timestamp)
	key = key or "a"
	timestamp = timestamp or os.time(os.date("!*t"))
	return string.format("sss_%s_%s", key, timestamp)
end

-- This function is responsible for returning the filename of the save with the
-- latest timestamp. The filename should not have the .ess extension or any leading
-- path information. E.g., a value of "my_save" is valid, but "Saves/my_save.ess" is
-- not valid.
-- Two values are returned. The first is the name of the latest save. The second is
-- the timestamp of that save.
local function getNewestSave(filterToQuickSaves)
	filterToQuickSaves = filterToQuickSaves or false

	local newestSave = nil
	local newestTimestamp = 0
	for file in lfs.dir("saves") do
		if (string.endswith(file, ".ess")) then
			-- Make sure we're filtering to only quicksaves if we're set to do so.
			if (not filterToQuickSaves or (filterToQuickSaves and string.sub(file, 5, 5) == "q")) then
				-- Check to see if the file is newer than our current newest file.
				local lastModified = lfs.attributes("saves/" .. file, "modification")
				if (lastModified > newestTimestamp) then
					newestSave = file
					newestTimestamp = lastModified;
				end
			end
		end
	end

	if (newestSave ~= nil) then
		return string.sub(newestSave, 1, -5), newestTimestamp
	end
end

-- Clear out any old saves beyond config.maxSaveCount.
local function clearOldSaves()
	-- If we have a value of 0, don't clear old saves.
	if (config.maxSaveCount == 0) then
		return;
	end

	-- Gather a list of all the managed saves.
	local saves = {}
	local saveTypes = {}
	for file in lfs.dir("saves") do
		-- Only clear out SSS saves, but never clear out forced saves.
		if (string.startswith(file, "sss_") and string.endswith(file, ".ess") and string.sub(file, 5, 5) ~= "f") then
			local timestamp = tonumber(string.sub(file, 7, -5))
			table.insert(saves, timestamp)
			saveTypes[timestamp] = string.sub(file, 5, 5)
		end
	end
	
	-- Ensure that the table is sorted.
	table.sort(saves)

	-- If we have more saves than we allow, it's time to start deleting.
	for i = 1, #saves - config.maxSaveCount do
		local timestamp = saves[i]
		local fileName = getSaveName(saveTypes[timestamp], timestamp)
		if (os.remove("saves/" .. fileName .. ".ess")) then
			print("[nc-sss] Deleting old save: " .. fileName)
		else
			print("[nc-sss] Warning! Failed to delete old save: " .. fileName)
		end
	end
end

-- Loads the configuration file for use.
local function loadConfig()
	-- Clear any current config values.
	config = {}

	-- First, load the defaults.
	table.copy(defaultConfig, config)

	-- Then load any other values from the config file.
	local configJson = json.loadfile("nc_sss_config")
	if (configJson ~= nil) then
		table.copy(configJson, config)
	end

	print("[nc-sss] Loaded configuration:")
	print(json.encode(config, { indent = true }))
end
loadConfig()

-- Saves the configuration to the local file.
local function saveConfig()
	json.savefile("nc_sss_config", config)
	
	print("[nc-sss] Saved configuration:")
	print(json.encode(config, { indent = true }))
end

-- Autosave function. Executes when autosaveTimer iterates, which should be every
-- minute. The number of passes in the autosave is kept, compared to the number of
-- minutes between saves in the configuration.
local autosaveTimer = nil
local autosavePasses = 0
local blockAutosaves = true
local function autosave()
	if (not config.saveOnTimer or blockAutosaves or tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	-- Another minute has passed.
	autosavePasses = autosavePasses + 1
	if (autosavePasses >= config.timeBetweenAutoSaves) then
		tes3.saveGame({ file = "autosave" })
	end
end

-- Recreates the autosave timer. This is necessary because when the game loads, all
-- timers are destroyed.
local function createAutosaveTimer()
	autosavePasses = 0
	autosaveTimer = timer.start(60, autosave, 0)
end
createAutosaveTimer()

-- Resets the autosave timer. We don't want saves to be too close to one another. So
-- we reset the autosave timer and the number of passes completed every time a save
-- is done.
local function resetAutosaveTimer()
	autosavePasses = 0
	timer.t = config.timeBetweenAutoSaves
	timer.reset(autosaveTimer)
end

-- Initialization event. This happens after the game has finished loading game data,
-- and is about to show the main menu. The only thing we want to do here is let the
-- log know that we're up and going.
local function initialized(e)
	print("[nc-sss] Initialized MWSE Sophisticated Save System v1.0.0.")
end
event.register("initialized", initialized)

-- Check for combat start save event. This event can be a bit tricky. We need to see
-- if it is the player entering combat, and if it is, we want to check their inCombat
-- flag to see if they are newly starting combat.
local function combatStart(e)
	-- Do we care about this save event?
	if (not config.saveOnCombatStart or blockAutosaves or tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	-- The event variables are mobile actors, not references. We only care about the
	-- player.
	local mobilePlayer = tes3.getMobilePlayer()
	if (e.actor ~= mobilePlayer) then
		return
	end

	-- If the combat is starting and the player isn't already in combat, this is a
	-- new combat session and we can care to make a save.
	if (e.actor.inCombat) then
		return
	end

	-- If we've no reason to ignore the event, make an autosave.
	print("[nc-sss] Creating autosave for combat start.")
	tes3.saveGame({ file = "autosave" })
end
event.register("combatStart", combatStart)

-- Check for combat stop save event. This also has some gotchas to it. The player
-- combat stop event isn't reliable, but NPCs are mostly reliable. So we'll check to
-- see if the player is out of combat when this event ends and cause a save.
local function combatStopped(e)
	-- Do we care about this save event?
	if (not config.saveOnCombatEnd or blockAutosaves or tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	-- The event variables are mobile actors, not references. We only care about
	-- when the player is not in combat.
	local mobilePlayer = tes3.getMobilePlayer()
	if (mobilePlayer.inCombat) then
		return
	end

	-- If we've no reason to ignore the event, make an autosave.
	print("[nc-sss] Creating autosave for combat end.")
	tes3.saveGame({ file = "autosave" })
end
event.register("combatStopped", combatStopped)

-- Check for cell change event.
local function cellChanged(e)
	-- Do we care about this save event?
	if (not config.saveOnCellChange or blockAutosaves or tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	-- If we've no reason to ignore the event, make an autosave.
	print("[nc-sss] Creating autosave for cell change.")
	tes3.saveGame({ file = "autosave" })
end
event.register("cellChanged", cellChanged)

-- Load event. Called prior to the game actually being loaded. The load save name
-- can be overridden. We will do this when loading quick saves
local function load(e)
	-- Ignore the event if it's a new game.
	if (e.newGame) then
		return
	end

	-- If we're doing a quickload and are set to use the latest save, find what save
	-- to use instead.
	if (e.quickload == true) then
		local newestSave = getNewestSave(not config.loadLatestSave)
		if (newestSave ~= nil) then
			e.filename = newestSave
		end
	end

	-- Show the currently loading save.
	print("[nc-sss] Loading save: " .. e.filename)

	-- Block autosaves from happening until our load has resolved.
	blockAutosaves = true
end
event.register("load", load)

-- Game has finished loading. We'll use the opportunity to reload the configuration
-- so it is safely bound to the current save.
local function loaded(e)
	-- (Re)create autosave timer.
	createAutosaveTimer()

	-- Unblock autosaves from happening.
	blockAutosaves = false
end
event.register("loaded", loaded)

-- Save event. Called prior to the game saving. Here, we'll take advantage of quick-
-- saves and autosaves, and change the save filename/name.
local function save(e)
	-- Are we holding the alt key when quicksaving?
	if (e.filename == "quiksave" and mwse.virtualKeyPressed(18)) then
		-- If we're also holding shift, bring up config. Otherwise do a hard save.
		if (mwse.virtualKeyPressed(160)) then
			configShowMainMenu()
		else
			tes3.saveGame({
				file = "sss_f_" .. os.time(os.date("!*t")),
				name = string.format("Save Game (%s)", os.date("%x %X"))
			})
		end
		return false
	end

	-- Redirect quick/auto saves to use sss_* saves.
	if (e.filename == "quiksave") then
		e.filename = "sss_q_" .. os.time(os.date("!*t"))
		e.name = string.format("Quicksave (%s)", os.date("%x %X"))
	elseif (e.filename == "autosave") then
		-- Ensure that we aren't autosaving too often.
		local now = os.clock()
		if (now - lastAutoSaveTimestamp < config.minimumTimeBetweenAutoSaves * 60) then
			print(string.format("[nc-sss] Prevented autosave, it has only been %d seconds since the last save.", now - lastAutoSaveTimestamp))
			return false
		end
		lastAutoSaveTimestamp = now

		-- Configure our save name/file.
		e.filename = "sss_a_" .. os.time(os.date("!*t"))
		e.name = string.format("Autosave (%s)", os.date("%x %X"))
	end

	-- Show the save.
	print(string.format("[nc-sss] Creating save: %s -> %s", e.name, e.filename))
end
event.register("save", save)

-- Saved event. Called after the game has successfully saved. We'll use this
-- opportunity to clear out any old saves that we don't need to care about anymore.
local function saved(e)
	-- Show the save information.
	print(string.format("[nc-sss] Created save: %s -> %s", e.name, e.filename))

	-- Reset the autosave timer.
	resetAutosaveTimer()

	-- Clean up any old saves.
	clearOldSaves()
end
event.register("saved", saved)

-- Configuration Menu: Enable/Disable Features
configShowEnableDisableFeatureMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then -- Unrestricted Quick Load
			config.loadLatestSave = not config.loadLatestSave
		elseif (e.button == 1) then -- Every X Minutes
			config.saveOnTimer = not config.saveOnTimer
		elseif (e.button == 2) then -- On Combat Start
			config.saveOnCombatStart = not config.saveOnCombatStart
		elseif (e.button == 3) then -- On Combat End
			config.saveOnCombatEnd = not config.saveOnCombatEnd
		elseif (e.button == 4) then -- On Cell Change
			config.saveOnCellChange = not config.saveOnCellChange
		else -- Unhandled button. Go back to the main menu.
			configShowMainMenu()
			return;
		end
	end

	-- Show menu. Delay it by one frame.
	tes3.messageBox({
		message = "SSS Configuration Menu\nEnable/Disable Features",
		buttons = {
			"Unrestricted Quick Load: " .. (config.loadLatestSave and "Enabled" or "Disabled"),
			"Autosave Every " .. config.timeBetweenAutoSaves .. " Minutes: " .. (config.saveOnTimer and "Enabled" or "Disabled"),
			"Autosave on Combat Start: " .. (config.saveOnCombatStart and "Enabled" or "Disabled"),
			"Autosave on Combat End: " .. (config.saveOnCombatEnd and "Enabled" or "Disabled"),
			"Autosave on Cell Change: " .. (config.saveOnCellChange and "Enabled" or "Disabled"),
			"Back"
		},
		callback = configShowEnableDisableFeatureMenu
	})
end

configShowConfigSaveCountMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then -- -1 Save
			if (config.maxSaveCount > 0) then
				config.maxSaveCount = config.maxSaveCount - 1
			end
		elseif (e.button == 2) then -- +1 minute
			config.maxSaveCount = config.maxSaveCount + 1
		else -- Unhandled button. Go back to the main menu.
			configShowMainMenu()
			return;
		end
	end

	-- Show menu. Delay it by one frame.
	tes3.messageBox({
		message = "Number of saves to keep: " .. (config.maxSaveCount ~= 0 and config.maxSaveCount or "All"),
		buttons = { "-", "Back", "+" },
		callback = configShowConfigSaveCountMenu
	})
end

configShowConfigTimerMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then -- -1 minute
			if (config.timeBetweenAutoSaves > 1) then
				config.timeBetweenAutoSaves = config.timeBetweenAutoSaves - 1
				resetAutosaveTimer()
			end
		elseif (e.button == 2) then -- +1 minute
			config.timeBetweenAutoSaves = config.timeBetweenAutoSaves + 1
			resetAutosaveTimer()
		else -- Unhandled button. Go back to the main menu.
			configShowMainMenu()
			return;
		end
	end

	-- Show menu. Delay it by one frame.
	tes3.messageBox({
		message = "Time between saves: " .. config.timeBetweenAutoSaves .. "m",
		buttons = { "-", "Back", "+" },
		callback = configShowConfigTimerMenu
	})
end

configShowConfigMinimumTimerMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then -- -1 minute
			if (config.minimumTimeBetweenAutoSaves > 1) then
				config.minimumTimeBetweenAutoSaves = config.minimumTimeBetweenAutoSaves - 1
				resetAutosaveTimer()
			end
		elseif (e.button == 2) then -- +1 minute
			config.minimumTimeBetweenAutoSaves = config.minimumTimeBetweenAutoSaves + 1
			resetAutosaveTimer()
		else -- Unhandled button. Go back to the main menu.
			configShowMainMenu()
			return;
		end
	end

	-- Show menu. Delay it by one frame.
	tes3.messageBox({
		message = "Minimum time between saves: " .. config.minimumTimeBetweenAutoSaves .. "m",
		buttons = { "-", "Back", "+" },
		callback = configShowConfigMinimumTimerMenu
	})
end

-- Configuration Menu: Main Menu
configShowMainMenu = function(e)
	if (e ~= nil) then
		if (e.button == 0) then -- Enable/Disable Features
			configShowEnableDisableFeatureMenu()
			return
		elseif (e.button == 1) then -- Configure Time Between Saves
			configShowConfigSaveCountMenu()
			return
		elseif (e.button == 2) then -- Configure Time Between Saves
			configShowConfigTimerMenu()
			return
		elseif (e.button == 3) then -- Configure Time Between Saves
			configShowConfigMinimumTimerMenu()
			return
		else -- Unhandled button. Close menu. Also save the configuration.
			saveConfig()
			return
		end
	end

	-- Show menu. Delay it by one frame.
	tes3.messageBox({
		message = "SSS Configuration Menu",
		buttons = {
			"Features & Events",
			"Save Count",
			"Time Between Saves",
			"Minimum Time Between Saves",
			"Close Menu"
		},
		callback = configShowMainMenu
	})
end
