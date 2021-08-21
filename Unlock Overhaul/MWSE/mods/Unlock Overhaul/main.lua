
local config = require("Unlock Overhaul.config") --- @type UnlockOverhaulConfig

--- Override for the vanilla logic to display a message when the player unlocks an object.
--- @param lockedRef tes3reference The reference being unlocked.
--- @param activatingActor tes3actor The actor doing the unlocking.
local function checkForKeyUnlock(lockedRef, activatingActor)
	local activator = activatingActor.reference
	local lockNode = lockedRef.lockNode

	-- Check to see if the activating actor has a key.
	local unlockingObject = nil
	local bypassTrap = false
	if (lockNode.key and activatingActor.inventory:contains(lockNode.key)) then
		unlockingObject = lockNode.key
		bypassTrap = config.keyBypassesTraps
	end

	-- No? How about with a skeleton key? But only if the lock level is >0.
	if (not unlockingObject and config.allowSkeletonKey and lockNode.level > 0) then
		local skeletonKey = tes3.getObject("skeleton_key")
		if (activatingActor.inventory:contains(skeletonKey)) then
			unlockingObject = skeletonKey
			bypassTrap = config.skeletonKeyBypassesTraps
		end
	end

	-- Trigger event.
	local eventData = event.trigger("UnlockOverhaul:Unlock", {
		reference = lockedRef,
		unlocker = activator,
		with = unlockingObject,
		locked = unlockingObject == nil,
		bypassTrap = bypassTrap,
		showMessage = true,
	})

	-- Was the logic blocked?
	if (eventData.block) then
		return eventData.bypassTrap
	end

	-- Was the object unlocked?
	if (not eventData.locked) then
		lockNode.locked = false
		lockedRef.modified = true
		if (activator == tes3.player) then
			tes3.game:clearTarget()

			-- Did we unlock it with a key?
			if (eventData.with and eventData.showMessage) then
				tes3.messageBox("%s %s", eventData.with.name, tes3.findGMST(tes3.gmst.sKeyUsed).value)
			end
		end
	end

	-- Let the trap system know we successfully unlocked.
	return eventData.bypassTrap
end

--- Generates the necessary patchs to replace key checks in Morrowind.exe.
--- @param startAddress number Where the patch begins.
--- @param endAddress number Where the patch ends.
local function replaceKeyCheckLogic(startAddress, endAddress)
	-- Zero out existing vanilla logic.
	mwse.memory.writeNoOperation({ address = startAddress, length = endAddress - startAddress })

	-- Establish call for following function call.
	mwse.memory.writeBytes({
		address = startAddress,
		bytes = {
			0x8B, 0x4C, 0x24, 0x14,       -- mov ecx, [esp+0x80+var_0x6C]
			0x51,                         -- push ecx
			0x8B, 0xCD,                   -- mov ecx, ebp
			0x90, 0x90, 0x90, 0x90, 0x90, -- call lua:checkForKeyUnlock
			0x84, 0xC0,                   -- test al, al
			0x74, 0x05,                   -- jz short $+0x7 ; skip the next line
			0xC6, 0x44, 0x24, 0x13, 0x01, -- mov [esp+0x80+var_0x6D], 1
		},
	})

	-- Call our checkForKeyUnlock function.
	mwse.memory.writeFunctionCall({
		address = startAddress + 0x7,
		call = checkForKeyUnlock,
		signature = {
			this = "tes3object",
			arguments = {
				"tes3object",
			},
			returns = "bool",
		},
	})
end

local function onInitialized()
	replaceKeyCheckLogic(0x4E9DF4, 0x4E9E86)
	replaceKeyCheckLogic(0x4EACF8, 0x4EAD8A)
end
event.register("initialized", onInitialized)

dofile("Unlock Overhaul.mcm")
