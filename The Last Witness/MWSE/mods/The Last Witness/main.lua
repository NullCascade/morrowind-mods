
-- A list of currently tracked crimes.
local crimes = {}

-- Quick access to all crimes witnessed by a given base object.
local crimesByWitness = {}

-- Create a crime table, and insert it into the crimes table.
local function createCrimeStructure(e)
	local crime = {}

	crime.type = e.type
	crime.value = e.value
	crime.timestamp = e.realTimestamp
	
	crime.witnesses = {}

	table.insert(crimes, crime)
	return crime
end

-- Finds a crime table matching the given crimeWitnessed event data.
local function findCrimeStructure(e)
	for _, crime in ipairs(crimes) do
		if (crime.timestamp == e.realTimestamp and crime.type == e.type and crime.value == e.value) then
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
	crime.witnesses[baseObject] = e.position

	-- Cache the crime by the witness.
	local byWitness = crimesByWitness[baseObject]
	if (byWitness == nil) then
		byWitness = {}
		crimesByWitness[baseObject] = byWitness
	end
	byWitness[crime] = e.position
end
event.register("crimeWitnessed", onCrimeWitnessed)

-- When a character dies, go look for any crimes by that witness and remove the witness.
-- If the witness list is then empty, forgive the crime.
local function onDeath(e)
	local baseObject = e.reference.baseObject
	local witnessedCrimes = crimesByWitness[baseObject]
	if (witnessedCrimes == nil) then
		return
	end

	local removeList = {}
	for crime, _ in pairs(witnessedCrimes) do
		table.insert(removeList, crime)
	end

	for _, crime in ipairs(removeList) do
		witnessedCrimes[crime] = nil
		crime.witnesses[baseObject] = nil

		if (table.empty(crime.witnesses)) then
			tes3.messageBox("The last witness has been killed. Crime forgiven.")
			tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty - crime.value
			table.removevalue(crimes, crime)
		else
			tes3.messageBox("One more witness killed. %d remain.", table.size(crime.witnesses))
		end
	end

	if (table.empty(witnessedCrimes)) then
		crimesByWitness[baseObject] = nil
	end
end
event.register("death", onDeath)

-- When the game is reloaded, clear any crime data. Crime forgiveness won't persist between saves.
local function onLoaded()
	crimes = {}
	crimesByWitness = {}
end
event.register("loaded", onLoaded)
