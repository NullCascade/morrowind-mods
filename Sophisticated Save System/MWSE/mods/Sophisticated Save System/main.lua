
local config = require("Sophisticated Save System.config")
local interop = require("Sophisticated Save System.interop")

-- Ensure we don't have an old version installed.
local lfs = require("lfs")
if (lfs.attributes("Data Files/MWSE/lua/nc/save/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/save/", true)) then
		mwse.log("[Sophisticated Save System] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Sophisticated Save System] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/save' and restart Morrowind.")
		return
	end
end

-- Generates a save name with a keyed meaning. These meanings are:
--  a: Autosave, either by the usual resting or from an event.
--  q: Quicksave, with the usual hotkey.
--  f: Forced save, created with Alt+Quicksave.
function interop.getSaveName(key, timestamp)
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
function interop.getNewestSave(filterToQuickSaves)
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
function interop.clearOldSaves()
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
		local fileName = interop.getSaveName(saveTypes[timestamp], timestamp)
		if (not os.remove("saves/" .. fileName .. ".ess")) then
			mwse.log("[Sophisticated Save System] Warning: Failed to delete old save: " .. fileName)
		end
	end
end

-- Queue up an autosave.
local needToSave = false
function interop.queueAutosave()
	needToSave = true
end

-- Events that will reset the save throttling cooldown.
local saveThrottler = 0
local function resetSaveThrottler()
	saveThrottler = os.clock()
	needToSave = false
end

-- Redirect the quickload feature to find our actually latest save.
local function onLoad(e)
	-- Ignore the event if it's a new game.
	if (e.newGame) then
		return
	end

	-- If we're doing a quickload and are set to use the latest save, find what save
	-- to use instead.
	if (e.quickload == true) then
		local newestSave = interop.getNewestSave(not config.loadLatestSave)
		if (newestSave ~= nil) then
			e.filename = newestSave
		end
	end

	-- Reset the save cooldown.
	resetSaveThrottler()
end
event.register("load", onLoad)

-- Main save begin logic.
local function onSave(e)
	-- Are we holding the alt key when quicksaving? Perform a hard save.
	if (e.filename == "quiksave" and mwse.virtualKeyPressed(18)) then
		tes3.saveGame({
			file = interop.getSaveName("f"),
			name = string.format("%s (%s)", tes3.player.cell.name, os.date("%x %X")),
		})
		return false
	end

	-- Redirect quick/auto saves to use sss_* saves.
	if (e.filename == "quiksave") then
		e.filename = interop.getSaveName("q")
		e.name = string.format("Quicksave (%s)", os.date("%x %X"))
	elseif (e.filename == "autosave") then
		e.filename = interop.getSaveName("a")
		e.name = string.format("Autosave (%s)", os.date("%x %X"))
	end

	-- Reset our throttler.
	resetSaveThrottler()
end
event.register("save", onSave)

-- Saved event. Called after the game has successfully saved. We'll use this
-- opportunity to clear out any old saves that we don't need to care about anymore.
local function onSaved(e)
	-- Show the save information.
	if (config.logSaves) then
		mwse.log("Created save: %s -> %s", e.name, e.filename)
	end

	-- Clean up any old saves.
	interop.clearOldSaves()
end
event.register("saved", onSaved)

-- Checks to make sure that both the game can accept a save from this context and that we are ready to save.
function interop.canPerformSave()
	return not tes3.dataHandler.backgroundThreadRunning -- Prevent saving when there's something in the background thread.
		and tes3.worldController.charGenState.value == -1 -- We don't want to save before chargen is over.
		and (os.clock() - saveThrottler > config.minimumTimeBetweenAutoSaves * 60) -- Prevent saves from happening too often.
end

-- Autosave on combat start.
local function onCombatStarted(e)
	if (config.saveOnCombatStart) then
		interop.queueAutosave()
	end
end
event.register("combatStarted", onCombatStarted)

-- Autosave on combat end.
local function onCombatStopped(e)
	if (config.saveOnCombatStart) then
		interop.queueAutosave()
	end
end
event.register("combatStopped", onCombatStopped)

-- Autosave on combat end.
local function onCellChanged(e)
	if (config.saveOnCellChange) then
		interop.queueAutosave()
	end
end
event.register("cellChanged", onCellChanged)

-- Autosave on a timer.
local function onTimerSave(e)
	if (config.saveOnTimer) then
		interop.queueAutosave()
	end
end
timer.register("NC:SSS:Save", onTimerSave)

-- Only save during simulate events.
local function onSimulate(e)
	if (needToSave and interop.canPerformSave()) then
		tes3.saveGame({ file = "autosave" })
	end
end
event.register("simulate", onSimulate)

-- Setup MCM.
local function registerModConfig()
	dofile("Sophisticated Save System.mcm")
end
event.register("modConfigReady", registerModConfig)

mwse.log("[Sophisticated Save System] Initialized MWSE Sophisticated Save System v2.0.0.")
