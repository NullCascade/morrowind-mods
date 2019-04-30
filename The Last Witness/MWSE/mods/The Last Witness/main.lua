
-- A list of currently tracked crimes.
local crimes = {}

-- Quick access to all crimes witnessed by a given base object.
local crimesByWitness = {}

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
			tes3.messageBox("The last witness has been killed. Crime forgiven.")
			tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty - crime.value
			table.removevalue(crimes, crime)
		else
			tes3.messageBox("One more witness killed. %d remain.", #crime.witnesses)
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

-- TODO:
-- Only give a 5 in-game minute (configurable) grace period where witnesses can be killed.
-- MCM
