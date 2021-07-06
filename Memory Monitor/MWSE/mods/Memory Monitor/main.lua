
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

local config = mwse.loadConfig("Memory Monitor", {
	visibleThreshold = 0.5,
	criticalThreshold = 0.90,
	criticalSaveFile = "memory_low",
	criticalSaveName = "Critical Memory Warning",
})

local function getMemoryUsageInMB()
	return mwse.getVirtualMemoryUsage() / 1024 / 1024
end

-- The theoretical max memory. For VirtualMemoryUsage, it should be 4GB-based. But 3.5 might be safer.
local MAX_MEMORY_USAGE = 4096

-- Handles onto our common UI elements.
local MemoryUsage
local MemoryUsageWidget

-- Just update every frame.
local shownCriticalMessage = false
local function updateMemoryUseBar()
	if (MemoryUsage) then
		-- Set the fill bar value.
		local currentUsage = getMemoryUsageInMB()
		MemoryUsageWidget.current = currentUsage

		-- Change the color based on how full we are.
		local ratio = currentUsage / MAX_MEMORY_USAGE
		local colorAdjusted = (math.clamp(ratio, 0.5, 1.0) - 0.5) * 2
		MemoryUsageWidget.fillColor = { 1.0 * colorAdjusted, 1.0 * (1 - colorAdjusted), 0 }

		-- Show/hide the element based on the config threshold.
		MemoryUsage.visible = ratio > config.visibleThreshold

		-- Have we hit a critical threshold?
		if (not shownCriticalMessage and ratio > config.criticalThreshold) then
			tes3.messageBox({
				message = string.format("Memory Monitor: Critical threshold hit! You are using %.2f GB of memory.", getMemoryUsageInMB() / 1024),
				buttons = { "Continue", "Save", "Save & Quit" },
				callback = function(e)
					if (e.button == 1) then
						tes3.saveGame({ file = config.criticalSaveFile, name = config.criticalSaveName })
					elseif (e.button == 2) then
						tes3.saveGame({ file = config.criticalSaveFile, name = config.criticalSaveName })
						event.register("simulate", function() os.exit() end)
					end
				end,
			})
			shownCriticalMessage = true
		end
	end
end
event.register("enterFrame", updateMemoryUseBar)

local function onMemoryUsageHelp(e)
	local tooltip = tes3ui.createTooltipMenu()
	tooltip:createLabel({ text = string.format("Total usage: %d MB", getMemoryUsageInMB()) })
	tooltip:createLabel({ text = string.format("Lua usage: %d MB", collectgarbage("count") / 1024) })
end

-- Create our menu with the main HUD.
local function onMenuMultiActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Find our parent container.
	local MenuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	local MenuMap_panel = MenuMulti:findChild(tes3ui.registerID("MenuMap_panel"))
	local MenuMap_panel_parent = MenuMap_panel.parent

	-- Fix the parent container to allow for more things to be added to it.
	MenuMap_panel_parent.flowDirection = "top_to_bottom"
	MenuMap_panel_parent.alpha = tes3.worldController.menuAlpha

	MemoryUsage = MenuMap_panel_parent:createFillBar({ id = tes3ui.registerID("NullC:MemoryUsage"), current = getMemoryUsageInMB(), max = MAX_MEMORY_USAGE })
	MemoryUsage.width= 65
	MemoryUsage.height = 10
	MemoryUsage:register("help", onMemoryUsageHelp)
	MemoryUsageWidget = MemoryUsage.widget
	MemoryUsageWidget.showText = false

	-- Move this to the top.
	MenuMap_panel_parent:reorderChildren(0, -1, 1)

	-- Trigger an update.
	MenuMulti:updateLayout()
end
event.register("uiActivated", onMenuMultiActivated, { filter = "MenuMulti", priority = -10 })
