
--[[
	Mod Initialization: Memory Monitor
	Author: NullCascade

	This simple mod checks every so often to see what the memory usage of Morrowind is. If it is approaching the
	4 GB limit, the mod will warn that it is time to save/reload.
]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180726) then
	mwse.log("[Memory Monitor] Build date of %s does not meet minimum build date of 20180726.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/memmon/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/memmon/", true)) then
		mwse.log("[Memory Monitor] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Memory Monitor] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/memmon' and restart Morrowind.")
		return
	end
end

local config = mwse.loadConfig("Memory Monitor")

local function checkMemoryUsage()
	local usedMemory = mwse.getVirtualMemoryUsage() / 1073741824
	if (usedMemory > config.criticalThreshold) then
		tes3.messageBox({
			message = string.format("You are dangerously close to the 4 GB memory limit. Consider saving and reloading to clear data from memory.\nUsage: %.2f GB", usedMemory),
			buttons = { "OK" }
		})
	elseif (usedMemory > config.warnThreshold) then
		tes3.messageBox({ message = string.format("Warning: Approaching 4 GB memory limit.\nUsage: %.2f GB", usedMemory) })
	end
end

local function onLoaded(e)
	timer.start(config.checkInterval, checkMemoryUsage, 0)
end
event.register("loaded", onLoaded)
