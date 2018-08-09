
--[[
	Mod Initialization: Happy Harvesting
	Author: NullCascade

	This file provides a very simple, generic-case auto-harvesting for organic
	containers in Morrowind. There are no graphic replacements. There are no fancy
	effects. It behaves just like the vanilla interaction with ingredients, save for
	that it auto-loots the inventory instead of opening the interface. It applies
	to any organic, unscripted container in the game. This makes it compatible with
	any graphic herbalism mod, it will just harvest anything that those mods miss.
]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180728) then
	mwse.log("[Happy Harvesting] Build date of %s does not meet minimum build date of 20180728.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/harvest/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/harvest/", true)) then
		mwse.log("[Happy Harvesting] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Happy Harvesting] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/harvest' and restart Morrowind.")
		return
	end
end

local config = mwse.loadConfig("Happy Harvesting")
if (config == nil) then
	config = {
		blacklist = {}
	}
end

local function onActivate(e)
	local target = e.target
	local container = target.object
	local baseObject = container
	if (container.isInstance) then
		baseObject = container.baseObject
	end
	
	-- Make sure that we're looking at an unowned, unscripted, organic container. Also check the blacklist.
	if (container.objectType ~= tes3.objectType.container) then
		return
	elseif (container.organic ~= true) then
		return
	elseif (container.script ~= nil) then
		return
	elseif (tes3.getOwner(target) ~= nil) then
		return
	elseif (table.find(config.blacklist, baseObject.id) ~= nil) then
		return
	end

	-- When a container has yet to be opened, it doesn't exist as an instance.
	-- Instead it is the base object. When the item is first activated it clones the
	-- container to an instance. We want to force this to happen so we don't edit
	-- the base record. This also makes sure that our leveled items are resolved.
	if (target:clone()) then
		container = target.object
	end

	-- Container keeping track of items we've removed.
	local removedItems = {}

	-- At this point we know we want this container.
	local countHarvested = 0
	local inventory = container.inventory
	for stack in tes3.iterate(inventory.iterator) do
		-- Store the item for later removal.
		local item = stack.object
		removedItems[item.id] = stack.count

		-- Add the item to the player.
		countHarvested = countHarvested + stack.count
		mwscript.addItem({ reference = tes3.player, item = item.id, count = stack.count })

		-- Give some feedback to the user by playing the pickup sound and showing a message box.
		tes3.playItemPickupSound({ item = item.id, pickup = true })
		tes3.messageBox({ message = "Harvested " .. stack.count .. " " .. item.name .. (stack.count > 1 and "s" or "") })
	end

	-- Remove items we've added from the container.
	if (countHarvested > 0) then
		for id, count in pairs(removedItems) do
			mwscript.removeItem({ reference = target, item = id, count = count })
		end
	else
		-- If nothing was removed, let the user know.
		tes3.messageBox({ message = "Nothing was harvested." })
	end

	-- Consume the event.
	return false
end
event.register("activate", onActivate)

-- 
-- Set up Mod Config Menu support.
-- 

local modConfig = require("Happy Harvesting.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Happy Harvesting", modConfig)
end
event.register("modConfigReady", registerModConfig)
