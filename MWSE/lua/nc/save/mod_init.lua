
--[[
	Mod Initialization: Sensational Save System
	Author: NullCascade

	This mod is responsible for changing how saves are done in Morrowind.

	Features:
		* Overrides autosaves and quicksaves to keep a variable amount of rotating
		  saves.
		* Autosaves the game every 10 minutes. The time between saves is customizable.
		* Overrides the quickload behavior to load the newest save, instead of the
		  quicksave specifically. This can be changed to only load the newest quicksave,
		  which is closer to vanilla behavior.
]]--

local lfs = require("lfs")

-- Default configuration values.
local defaultConfig = {
	timeBetweenAutoSaves = 10,
	minimumTimeBetweenAutoSaves = 5,
	maxSaveCount = 10,
	loadLatestSave = true,
	saveOnTimer = true,
	saveOnCombatStart = true,
	saveOnCombatEnd = true,
	saveOnCellChange = true,
}

-- Configuration table.
local config = table.copy(defaultConfig)

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
local function loadConfig(useSaveData)
	-- Clear any current config values.
	config = {}

	-- First, load the defaults.
	table.copy(defaultConfig, config)

	-- Then load any other values from the save.
	if (useSaveData == true) then
		local data = tes3.getPlayerRef().data
		if (data.nc_sss ~= nil and data.nc_sss.config ~= nil) then
			for k, v in pairs(data.nc_sss.config) do
				config[k] = v
			end
		end
	end

	print("[nc-sss] Reloaded configuration.")
end
loadConfig()

-- Saves the configuration to the player's attached data.
local function saveConfig()
	-- Go through the config, and the default config. Save any values that do not
	-- match to the player's data.
	local data = tes3.getPlayerRef().data

	-- Create any modified values on the save file.
	data.nc_sss = { config = {} }
	for k, v in pairs(config) do
		if (v ~= defaultConfig[k]) then
			data.nc_sss.config[k] = v
		end
	end
end

-- Our config menus need to be forward declared so they can be moved between cleanly.
local configShowEnableDisableFeatureMenu
local configShowMainMenu

-- Configuration Menu: Enable/Disable Features
configShowEnableDisableFeatureMenu = function(e)
	-- Was this function called as an event?
	if (e ~= nil) then
		if (e.button == 0) then -- Unrestricted Quick Load
			config.loadLatestSave = not config.loadLatestSave
		else -- Unhandled button. Go back to the main menu.
			configShowMainMenu()
			return;
		end
	end

	-- Show menu. Delay it by one frame.
	timer.delayOneFrame(function()
		tes3.messageBox({
			message = "SSS Configuration Menu\nEnable/Disable Features",
			buttons = {
				"Unrestricted Quick Load: " .. (config.loadLatestSave and "Enabled" or "Disabled"),
				"Back"
			},
			callback = configShowEnableDisableFeatureMenu
		})
	end)
end

-- Configuration Menu: Main Menu
configShowMainMenu = function(e)
	if (e ~= nil) then
		if (e.button == 0) then -- Enable/Disable Features
			configShowEnableDisableFeatureMenu()
			return
		elseif (e.button == 1) then -- Enable/Disable Autosave Events
			
		elseif (e.button == 2) then -- Configure Time Between Saves
			
		else -- Unhandled button. Close menu.
			return
		end
	end

	-- Show menu. Delay it by one frame.
	timer.delayOneFrame(function()
		tes3.messageBox({
			message = "SSS Configuration Menu\nVersion 1.0.0",
			buttons = {
				"Enable/Disable Features",
				"Enable/Disable Autosave Events",
				"Configure Time Between Saves",
				"Close Menu"
			},
			callback = configShowMainMenu
		})
	end)
end

-- Autosave function. Executes when autosaveTimer iterates, which should be every
-- minute. The number of passes in the autosave is kept, compared to the number of
-- minutes between saves in the configuration.
local autosaveTimer = nil
local autosavePasses = 0
local function autosave()
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
	timer.reset(autosaveTimer)
end

-- Initialization event. This happens after the game has finished loading game data,
-- and is about to show the main menu. The only thing we want to do here is let the
-- log know that we're up and going.
local function initialized(e)
	print("[nc-sss] Initialized Super Save System v1.0.0.")
end
event.register("initialized", initialized)

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
end
event.register("load", load)

-- Game has finished loading. We'll use the opportunity to reload the configuration
-- so it is safely bound to the current save.
local function loaded(e)
	-- Reload configuration.
	loadConfig()

	-- (Re)create autosave timer.
	createAutosaveTimer()
end
event.register("loaded", loaded)

-- Save event. Called prior to the game saving. Here, we'll take advantage of quick-
-- saves and autosaves, and change the save filename/name.
local function save(e)
	-- Are we holding the alt key when saving?
	if (mwse.virtualKeyPressed(18)) then
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
		e.filename = "sss_a_" .. os.time(os.date("!*t"))
		e.name = string.format("Autosave (%s)", os.date("%x %X"))
	end

	-- Update the configuration on the player.
	saveConfig()

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
