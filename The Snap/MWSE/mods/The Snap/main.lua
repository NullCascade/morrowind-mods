
local infinityGauntlet = nil
local dust = nil

local function snapReference(reference)
	-- Only snap living things.
	local objectType = reference.object.objectType
	if (objectType ~= tes3.objectType.npc and objectType ~= tes3.objectType.creature) then
		return
	end

	-- Don't re-snap objects.
	local data = reference.data
	if (data.nc_snapped ~= nil) then
		return
	end

	if (math.random(1, 2) == 1) then
		data.nc_snapped = true
		mwse.log("%s was snapped!", reference)

		mwscript.drop({ reference = reference, item = dust, distance = 0 })
		mwscript.disable({ reference = reference })
		mwscript.setDelete({ reference = reference })
	else
		data.nc_snapped = false
		mwse.log("%s was spared.", reference)
	end
end

local function snapCell(cell)
	for reference in cell:iterateReferences() do
		snapReference(reference)
	end
end

local function snapCells()
	if (not tes3.player.data.nc_worldSnapped) then
		return
	end

	local cell = tes3.getPlayerCell()
	if (cell.isInterior) then
		snapCell(cell)
	else
		local exteriorCells = tes3.dataHandler.exteriorCells
		for i = 1, #exteriorCells do
			snapCell(exteriorCells[i].cell)
		end
	end
end
event.register("cellChanged", snapCells)
event.register("loaded", snapCells)

local function onInfinityGauntletEquipped(e)
	if (tes3.player.data.nc_worldSnapped) then
		return
	end

	tes3.player.data.nc_worldSnapped = true
	snapCells()
	tes3.playSound({
		reference = tes3.player,
		soundPath = "Fx\\thanos\\snap.wav",
	})
end

local function onInitialized()
	infinityGauntlet = tes3.getObject("wraithguard")
	dust = tes3.getObject("ashes_Dwemer")

	event.register("equipped", onInfinityGauntletEquipped, { filter = infinityGauntlet })
end
event.register("initialized", onInitialized)
