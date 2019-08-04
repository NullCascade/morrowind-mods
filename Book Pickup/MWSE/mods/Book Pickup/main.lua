--[[

	Causes books to be picked up by default, though shift can be held to read them instead.

--]]

local config = mwse.loadConfig("Book Pickup")
config = config or {}
if (config.pickupByDefault == nil) then
	config.pickupByDefault = true
end

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

	-- Ignore scripted references for now.
	if (item.script ~= nil) then
		return
	end

	-- Check for ownership.
	if (not tes3.hasOwnershipAccess({ target = reference })) then
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

	-- Add it to the player's inventory manually.
	mwscript.addItem({ reference = tes3.player, item = item, count = math.min(reference.stackSize or 1, 1) })
	mwscript.disable({ reference = reference })
	mwscript.setDelete({ reference = reference, delete = true })
	tes3.playItemPickupSound({ item = item })

	return false
end
event.register("activate", onActivate)


local function registerModConfig()
	local easyMCM = include("easyMCM.EasyMCM")
	if (easyMCM == nil) then
		return
	end

	local template = easyMCM.createTemplate("Book Pickup")
	template:saveOnClose("Book Pickup", config)

	local page = template:createPage()
	page:createOnOffButton{
		label = "Pickup by default?",
		variable = easyMCM.createTableVariable{
			id = "pickupByDefault",
			table = config
		}
	}

	easyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)

