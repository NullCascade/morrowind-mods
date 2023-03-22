--[[

	Causes books to be picked up by default, though shift can be held to read them instead.

--]]

if (mwse.buildDate < 20190818) then
	mwse.log("[Book Pickup] Error: MWSE version is out of date! Run MWSE-Updater.exe.")
	return
end

local defaultConfig = {
	pickupByDefault = true,
	checkOwnership = false,
}
local config = mwse.loadConfig("Book Pickup", defaultConfig)

local function onActivate(e)
	if (e.activator ~= tes3.player) then
		return
	end

	-- Get the item we're activating.
	local reference = e.target
	local item = reference.object
	if (item.objectType ~= tes3.objectType.book) then
		return
	end

	-- Is use enabled? Or was it blocked by a script?
	local itemData = reference.itemData
	if (not reference:testActionFlag(tes3.actionFlag.useEnabled)) then
		return
	end

	-- Check for ownership.
	local hasAccess = tes3.hasOwnershipAccess({ target = reference })
	if (config.checkOwnership and not hasAccess) then
		return
	end

	-- Holding shift restores normal behavior.
	local ic = tes3.worldController.inputController
	local isShiftDown = ic:isKeyDown(tes3.scanCode.leftShift) or ic:isKeyDown(tes3.scanCode.rightShift)

	-- Respect the config option for determining behavior.
	if (config.pickupByDefault and isShiftDown) then
		return
	elseif ((not config.pickupByDefault) and (not isShiftDown)) then
		return
	end

	-- Check for crime.
	if (not hasAccess) then
		tes3.triggerCrime({
			type = tes3.crimeType.theft,
			victim = itemData.owner,
			value = item.value,
		})
	end

	-- Add it to the player's inventory manually.
	tes3.addItem({
		reference = tes3.player,
		item = item,
		itemData = itemData,
		count = itemData and itemData.count or 1,
	})

	-- Remove invisibility
	tes3.removeEffects({
		reference = tes3.player,
		effect = tes3.effect.invisibility,
	})

	-- Delete the reference. Detach the itemData first.
	reference.itemData = nil
	reference:disable()
	mwscript.setDelete({ reference = reference, delete = true })

	return false
end
event.register("activate", onActivate, { priority = 10 })


local function registerModConfig()
	local mcm = require("mcm.mcm")
	if (mcm == nil) then
		return
	end

	local template = mcm.createTemplate("Book Pickup")
	template:saveOnClose("Book Pickup", config)

	local page = template:createPage()
	page:createOnOffButton{
		label = "Pickup by default?",
		variable = mcm.createTableVariable{
			id = "pickupByDefault",
			table = config
		}
	}

	page:createOnOffButton{
		label = "Disable picking owned?",
		variable = mcm.createTableVariable{
			id = "checkOwnership",
			table = config
		}
	}

	mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
