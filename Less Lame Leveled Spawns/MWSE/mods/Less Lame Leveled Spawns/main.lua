
local config = require("Less Lame Leveled Spawns.config")

--- Blocks the spawning of random creatures when it doesn't make sense.
--- @param e leveledCreaturePickedEventData
local function onCreaturePicked(e)
	-- No point in staying if there wasn't a result.
	if (e.pick == nil) then
		return
	end

	-- We only care about leveled creatures that come from a placed leveled creature reference.
	if (e.source ~= "reference") then
		return
	end

	-- We also just want to flat-out block all leveled creatures created during loading.
	if (config.blockSpawnsWhenLoading and tes3.dataHandler.nonDynamicData.isSavingOrLoading) then
		return false
	end

	-- Block spawns with a cooldown.
	if (config.blockSpawnsWithCooldown) then
		-- Get some information to make our decision.
		local spawnerData = e.spawner.data
		local lastPickTime = spawnerData.lastPickTime or 0
		local now = tes3.getSimulationTimestamp()
		local respawnTime = tes3.findGMST(tes3.gmst.fCorpseRespawnDelay).value

		if (now - lastPickTime < respawnTime) then
			return false
		end

		-- Update our spawner to mark the cooldown.
		spawnerData.lastPickTime = now
		e.spawner.modified = true
	end
end
event.register(tes3.event.leveledCreaturePicked, onCreaturePicked)

-- Create the MCM file.
dofile("Less Lame Leveled Spawns.mcm")
