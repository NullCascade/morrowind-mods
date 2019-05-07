
-- A list of currently tracked crimes.
local crimes = {}

-- Quick access to all crimes witnessed by a given base object.
local crimesByWitness = {}

-- Load configuration.
local config = mwse.loadConfig("The Last Witness") or {}
config.timeLimit = config.timeLimit or 10

-- Sorts crimes by their timestamps.
local function crimeSorter(a, b)
	return a.timestamp < b.timestamp
end

-- Create a crime table, and insert it into the crimes table.
local function createCrimeStructure(e)
	local crime = {}

	crime.type = e.type
	crime.value = e.value
	crime.timestamp = tes3.getSimulationTimestamp()
	crime.realTimestamp = e.realTimestamp
	
	crime.witnesses = {}

	table.insert(crimes, crime)
	table.sort(crimes, crimeSorter)
	return crime
end

-- Finds a crime table matching the given crimeWitnessed event data.
local function findCrimeStructure(e)
	for _, crime in ipairs(crimes) do
		if (crime.realTimestamp == e.realTimestamp and crime.type == e.type and crime.value == e.value) then
			return crime
		end
	end
end

-- When a crime is witnessed, we track the crime and add it to the lookup tables.
local function onCrimeWitnessed(e)
	local baseObject = e.witness.baseObject
	mwse.log("Crime (%s, %d gold) witnessed by %s at %s / %s", e.type, e.value, baseObject, e.position, e.realTimestamp)

	-- Find/create the crime and add this as a witness to it.
	local crime = findCrimeStructure(e) or createCrimeStructure(e)
	table.insert(crime.witnesses, baseObject)

	-- Cache the crime by the witness.
	local byWitness = crimesByWitness[baseObject]
	if (byWitness == nil) then
		byWitness = {}
		crimesByWitness[baseObject] = byWitness
	end
	byWitness[crime] = true
end
event.register("crimeWitnessed", onCrimeWitnessed)

-- When a character dies, go look for any crimes by that witness and remove the witness.
-- If the witness list is then empty, forgive the crime.
local function onDeath(e)
	-- Do we have crimes this actor has witnessed?
	local baseObject = e.reference.baseObject
	local witnessedCrimes = crimesByWitness[baseObject]
	if (witnessedCrimes == nil) then
		return
	end

	-- Gather a list of crimes to remove.
	local removeList = {}
	for crime, _ in pairs(witnessedCrimes) do
		table.insert(removeList, crime)
	end

	-- We can't do this in one pass, as we'll be modifying the collection we're operating on.
	for _, crime in ipairs(removeList) do
		-- Clear any associated tables.
		witnessedCrimes[crime] = nil
		table.removevalue(crime.witnesses, baseObject)

		-- Was this the last witness?
		if (#crime.witnesses == 0) then
			tes3.messageBox("The last witness has been killed.")
			tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty - crime.value
			table.removevalue(crimes, crime)
		end
	end

	-- Was this the last crime witnessed by this actor? If so, that table.
	if (table.empty(witnessedCrimes)) then
		crimesByWitness[baseObject] = nil
	end
end
event.register("death", onDeath)

local function onSave(e)
	tes3.player.data.nc_crimes = crimes
end
event.register("save", onSave)

-- When the game is reloaded, clear any crime data. Crime forgiveness won't persist between saves.
local function onLoaded()
	crimes = tes3.player.data.nc_crimes or {}
	crimesByWitness = {}
	
	-- Convert the serialized data to what we need.
	for _, crime in ipairs(crimes) do
		local serializedWitnesses = crime.witnesses
		crime.witnesses = {}
		for _, witness in ipairs(serializedWitnesses) do
			-- Get the witness object and add it to the witness list.
			local witnessId = string.match(witness, ":(.*)")
			local witnessObject = tes3.getObject(witnessId)
			table.insert(crime.witnesses, witnessObject)

			-- Fixup the quick lookup by witness table.
			local byWitness = crimesByWitness[witnessObject]
			if (byWitness == nil) then
				byWitness = {}
				crimesByWitness[witnessObject] = byWitness
			end
			byWitness[crime] = true
		end
	end
	
	-- Sort crimes again.
	table.sort(crimes, crimeSorter)

	-- We don't need the data redundantly stored.
	tes3.player.data.nc_crimes = nil
end
event.register("loaded", onLoaded)

-- Clear after a time.
local function onSimulate(e)
	-- Ignore the time limit if it's set to.
	if (config.timeLimit == 0 or #crimes == 0) then
		return
	end

	-- Get a list of crimes we need to remove.
	local removeList = {}
	local timeThreshold = e.timestamp - config.timeLimit/60
	for _, crime in ipairs(crimes) do
		if (timeThreshold > crime.timestamp) then
			table.insert(removeList, crime)
		end
	end

	-- Go through and remove the crimes.
	for _, crime in ipairs(removeList) do
		-- The base crime.
		table.removevalue(crimes, crime)

		-- Witness lookup.
		for _, witness in ipairs(crime.witnesses) do
			table.removevalue(crimesByWitness[witness], crime)
		end
	end

	-- Get a list of witnesses to clean up.
	removeList = {}
	for witness, crimeList in ipairs(crimesByWitness) do
		if (#crimeList == 0) then
			table.insert(removeList, witness)
		end
	end

	-- And clear the witnesses.
	for _, witness in ipairs(removeList) do
		crimesByWitness[witness] = nil
	end
end
event.register("simulate", onSimulate)

-- Handle mod config menu.
local function registerModConfig()
	local easyMCM = include("easyMCM.EasyMCM")
	if (easyMCM == nil) then
		return
	end

	local template = easyMCM.createTemplate("The Last Witness")
	template:saveOnClose("The Last Witness", config)

	local page = template:createPage()
	page:createSlider({
		label = "Time Limit",
		description = "The number of in-game minutes for witnesses to be silenced.",
		min = 1,
		max = 60,
		step = 1,
		jump = 5,
		variable = easyMCM.createTableVariable({
			id = "timeLimit",
			table = config,
		}),
	})

	easyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)
