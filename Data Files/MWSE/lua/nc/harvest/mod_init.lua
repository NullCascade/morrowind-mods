
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

function onActivate(e)
	local target = e.target
	local container = target.object
	
	-- Make sure that we're looking at an unscripted, orgnic container.
	if (container.objectType ~= tes3.objectType.container) then
		return
	elseif (container.organic ~= true) then
		return
	elseif (container.script ~= nil) then
		return
	end

	-- When a container has yet to be opened, it doesn't exist as an instance.
	-- Instead it is the base object. When the item is first activated it clones the
	-- container to an instance. We want to force this to happen so we don't edit
	-- the base record. This also makes sure that our leveled items are resolved.
	if (container.isInstance == false) then
		container:clone(target)

		-- Refresh the handle on our reference's object, since it has now changed.
		container = target.object
	end

	-- Container keeping track of items we've removed.
	local removedItems = {}

	-- At this point we know we want this container.
	local countHarvested = 0
	local playerRef = tes3.getPlayerRef()
	local inventory = container.inventory
	for stack in tes3.iterate(inventory.iterator) do
		-- Store the item for later removal.
		local item = stack.object
		removedItems[item.id] = stack.count

		-- Add the item to the player.
		countHarvested = countHarvested + stack.count
		mwscript.addItem({ reference = playerRef, item = item.id, count = stack.count })
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
