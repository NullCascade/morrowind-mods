
local infinityGauntlet = nil
local dust = nil

local snapFader = nil

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

		mwscript.drop({ reference = reference, item = dust, distance = 0 })
		mwscript.disable({ reference = reference })
		mwscript.setDelete({ reference = reference })
	else
		data.nc_snapped = false
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

local function startFaderWithCallback(params)
	local fader = params.fader
	fader:fadeTo(params)
	params.duration = params.duration + (params.duration + params.delay)
	timer.start(params)
end

local function onInfinityGauntletEquipped(e)
	if (tes3.player.data.nc_worldSnapped) then
		return
	end

	tes3.player.data.nc_worldSnapped = true

	snapFader:activate()

	startFaderWithCallback({ fader = snapFader, value = 0.0, duration = 0.01, delay = 2.0, callback = function()
		startFaderWithCallback({ fader = snapFader, value = 1.0, duration = 0.5, delay = 1.5, callback = function()
			tes3.playSound({
				reference = tes3.player,
				soundPath = "Fx\\thanos\\snap.wav",
			})

			snapCells()
	
			startFaderWithCallback({ fader = snapFader, value = 0.0, duration = 3.0, delay = 0.5, callback = function()
				snapFader:deactivate()
			end})
		end})
	end})
end

local function onInitialized()
	infinityGauntlet = tes3.getObject("wraithguard")
	dust = tes3.getObject("ashes_Dwemer")

	event.register("equipped", onInfinityGauntletEquipped, { filter = infinityGauntlet })
end
event.register("initialized", onInitialized)

local function updateSnapFader()
	snapFader:update()
end

local function faderSetup()
	-- Create the tentacle fader.
	snapFader = tes3fader.new()
	snapFader:setTexture("Textures\\Tx_Sky_Foggy.dds")
	snapFader:setColor({ color = { 1.0, 1.0, 1.0 }, flag = false })
	
	event.register("enterFrame", updateSnapFader)
end
event.register("initialized", faderSetup)
