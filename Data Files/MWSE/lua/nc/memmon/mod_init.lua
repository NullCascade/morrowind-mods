
--[[
	Mod Initialization: Memory Monitor
	Author: NullCascade

	This simple mod checks every so often to see what the memory usage of Morrowind is. If it is approaching the
	4 GB limit, the mod will warn that it is time to save/reload.
]]--

local config = json.loadfile("nc_memmon_config")

local function checkMemoryUsage()
	local usedMemory = mwse.getVirtualMemoryUsage() / 1073741824
	if (usedMemory > config.criticalThreshold) then
		tes3.messageBox({
			message = string.format("You are dangerously close to the 4 GB memory limit. Consider saving and reloading to clear data from memory.\nUsage: %.2f GB", usedMemory),
			buttons = { "OK"}
		})
	elseif (usedMemory > config.warnThreshold) then
		tes3.messageBox({ message = string.format("Warning: Approaching 4 GB memory limit.\nUsage: %.2f GB", usedMemory) })
	end
end

local function onLoaded(e)
	timer.start(config.checkInterval, checkMemoryUsage, 0)
end
event.register("loaded", onLoaded)
