
--[[
	Mod Initialization: Sensational Save System
	Author: NullCascade

	This mod is responsible for changing how saves are done in Morrowind.

	Features:
		* Overrides autosaves and quicksaves to keep a variable amount of rotating
		  saves.
		* Autosaves the game every 10 minutes.
		* Overrides the quickload behavior to load the newest save, instead of the
		  quicksave specifically.
]]--

local lfs = require("lfs")

-- Configuration table. These values are the default, latest values are in the save.
local config = {
	timeBetweenAutoSaves = 10,
	minimumTimeBetweenAutoSaves = 5,
	maxSaveCount = 10,
	loadLatestSave = true,
	saveEvents = {
		timer = true,
		combatStart = true,
		combatEnd = true,
		cellChange = true,
	}
}

-- This function is responsible for returning the filename of the save with the
-- latest timestamp. The filename should not have the .ess extension or any leading
-- path information. E.g., a value of "my_save" is valid, but "Saves/my_save.ess" is
-- not valid.
local function getNewestSave()
	local newestSave = nil
	local newestTimestamp = 0
	for file in lfs.dir("saves") do
		if (string.endswith(file, ".ess")) then
			local lastModified = lfs.attributes("saves/" .. file, "modification")
			if (lastModified > newestTimestamp) then
				newestSave = file
				newestTimestamp = lastModified;
			end
		end
	end

	if (newestSave ~= nil) then
		return string.sub(newestSave, 1, -5)
	end
end

-- Clear out any old saves beyond config.maxSaveCount.
local function clearOldSaves()
	-- Gather a list of all the managed saves.
	local saves = {}
	for file in lfs.dir("saves") do
		if (string.startswith(file, "sss_") and string.endswith(file, ".ess")) then
			table.insert(saves, tonumber(string.sub(file, 5, -5)))
		end
	end
	
	-- Ensure that the table is sorted.
	table.sort(saves)

	-- If we have more saves than we allow, it's time to start deleting.
	for i = 1, #saves - config.maxSaveCount do
		local fileName = "saves/sss_" .. saves[i] .. ".ess"
		if (os.remove(fileName)) then
			print("[nc-sss] Deleting old save: " .. fileName)
		else
			print("[nc-sss] Warning! Failed to delete old save: " .. fileName)
		end
	end
end

-- Autosave function. Executes when autosaveTimer iterates, which should be every
-- minute. The number of passes in the autosave is kept, compared to the number of
-- minutes between saves in the configuration.
local autosaveTimer = nil
local autosavePasses = 0
local function autosave()
	autosavePasses = autosavePasses + 1
	if (autosavePasses >= config.timeBetweenAutoSaves) then
		tes3.saveGame("autosave")
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
	print("[nc-sss] Initialized Super Save System v1.0.")
end
event.register("initialized", initialized)

-- Load event. Called prior to the game actually being loaded. The load save name
-- can be overridden. We will do this when loading quick saves
local function load(e)
	-- (Re)create autosave timer.
	createAutosaveTimer()

	-- Ignore the event if it's a new game.
	if (e.newGame) then
		return
	end

	-- If we're doing a quickload and are set to use the latest save, find what save
	-- to use instead.
	if (e.quickload == true and config.loadLatestSave == true) then
		local x = getNewestSave()
		print("Newest save: " .. x)
		e.filename = x
	end

	-- Show the currently loading save.
	print("[nc-sss] Loading save: " .. e.filename)
end
event.register("load", load)

-- Save event. Called prior to the game saving. Here, we'll take advantage of quick-
-- saves and autosaves, and change the save filename/name.
local function save(e)
	-- Redirect quick/auto saves to use sss_* saves.
	if (e.filename == "quiksave") then
		e.filename = "sss_" .. os.time(os.date("!*t"))
		e.name = string.format("Quicksave (%s)", os.date("%x %X"))
	elseif (e.filename == "autosave") then
		e.filename = "sss_" .. os.time(os.date("!*t"))
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
