--[[
	Mage Robes Integration

	Support module for Melchior Dahrk's Mage Robes mod, providing content onto modded NPCs.
]]--

if (mwse.buildDate < 20190115) then
	event.register("initialized", function()
		tes3.messageBox("Mage Robes Integration requires a newer version of MWSE. Please run MWSE-Update.exe.")
	end)
	return
end

-- Association between rank name and index.
local mgRank = {
	["associate"] = 0,
	["apprentice"] = 1,
	["journeyman"] = 2,
	["evoker"] = 3,
	["conjurer"] = 4,
	["magician"] = 5,
	["warlock"] = 6,
	["wizard"] = 7,
	["masterWizard"] = 8,
	["archMage"] = 9,
}

-- A list of factions that will be checked to apply robes to.
local supportedFactions = {
	["mages guild"] = true,
	["t_cyr_magesguild"] = true,
	["t_mw_magesguild"] = true,
	["t_sky_magesguild"] = true,
}

-- A dictionary of robe IDs to objects. Will be filled in post-initialization. Any new robes need to be defined here for quick lookup.
local robes = {
	["mg_c_robe_alc"] = false,
	["mg_c_robe_alcmas"] = false,
	["mg_c_robe_alt"] = false,
	["mg_c_robe_altmas"] = false,
	["mg_c_robe_arch"] = false,
	["mg_c_robe_con"] = false,
	["mg_c_robe_conmas"] = false,
	["mg_c_robe_des"] = false,
	["mg_c_robe_desmas"] = false,
	["mg_c_robe_enc"] = false,
	["mg_c_robe_encmas"] = false,
	["mg_c_robe_ill"] = false,
	["mg_c_robe_illmas"] = false,
	["mg_c_robe_mys"] = false,
	["mg_c_robe_mysmas"] = false,
	["mg_c_robe_nov"] = false,
	["mg_c_robe_res"] = false,
	["mg_c_robe_resmas"] = false,
}

-- Mods to not give robes to.
local modBlacklist = {}

-- NPCs to not give robes.
local npcBlacklist = {}

-- A map of magic skills, and their associated tag.
local magicSkillTags = {
	[tes3.skill.alchemy] = "alc",
	[tes3.skill.alteration] = "alt",
	[tes3.skill.conjuration] = "con",
	[tes3.skill.destruction] = "des",
	[tes3.skill.enchant] = "enc",
	[tes3.skill.illusion] = "ill",
	[tes3.skill.mysticism] = "mys",
	[tes3.skill.restoration] = "res",
}

-- Helper function. Returns the NPC's highest magic skill, as well as the rank in that skill.
local function getHighestMagicSkill(npc)
	local highestSkill = nil
	local highestValue = -100
	for skill, _ in pairs(magicSkillTags) do
		local value = npc.skills[skill+1]
		if (value > highestValue) then
			highestSkill = skill
			highestValue = value
		end
	end
	return highestSkill, highestValue
end

-- Fetches the robe, if applicable, for an NPC. Also fetches the robe that it would replace.
local function getRobeForNPC(npc)
	-- Check blacklist.
	if (npcBlacklist[npc.id:lower()] or modBlacklist[npc.sourceMod:lower()]) then
		-- mwse.log("Skipping robe assignment for %s. Blacklisted", npc.id)
		return false
	end

	-- Restrict by faction.
	local faction = npc.faction
	if (faction == nil or supportedFactions[faction.id:lower()] ~= true) then
		return false
	end

	-- Get the robe ID to use.
	local newRobesId = nil
	if (npc.factionRank >= mgRank.archMage) then
		newRobesId = "mg_c_robe_arch"
	elseif (npc.factionRank >= mgRank.conjurer) then
		local highestSkill = getHighestMagicSkill(npc)
		newRobesId = string.format("mg_c_robe_%smas", magicSkillTags[highestSkill])
	elseif (npc.factionRank >= mgRank.apprentice) then
		local highestSkill = getHighestMagicSkill(npc)
		newRobesId = string.format("mg_c_robe_%s", magicSkillTags[highestSkill])
	else
		newRobesId = "mg_c_robe_nov"
	end

	-- Make sure we have the robes.
	local newRobes = robes[newRobesId]
	if (not newRobes) then
		-- mwse.log("Skipping robe assignment for %s. Could not resolve new robes: %s.", npc.id, newRobesId)
		return false
	end

	-- Find the robes to remove.
	local oldRobes = nil
	for _, stack in pairs(npc.inventory) do
		local object = stack.object
		if (stack.count > 0 and object.objectType == tes3.objectType.clothing and object.slot == tes3.clothingSlot.robe) then
			-- Swap out the best robes only.
			if (oldRobes == nil or object.value > oldRobes.value) then
				oldRobes = object
			end
		end
	end

	-- Prevent swapping if the old robes have a script or enchantment.
	if (oldRobes) then
		if (oldRobes.value > newRobes.value) then
			-- mwse.log("Skipping robe assignment for %s. Previous robes: %s, which are more valuable.", npc.id, oldRobes.id)
			return false
		end
	end

	return true, newRobes, oldRobes
end

local function onInitialized()
	-- Load the config file.
	local config = mwse.loadConfig("Mage Robes")
	if (config == nil) then
		config = {
			modBlacklist = {
				"morrowind.esm",
				"tribunal.esm",
				"bloodmoon.esm",
			},
			npcBlacklist = {
				"galbedir",
				"skinkintreesshade",
			},
		}
	end
	config.modBlacklist = config.modBlacklist or {}
	config.npcBlacklist = config.npcBlacklist or {}

	-- Build our blacklists.
	for _, v in pairs(config.modBlacklist) do
		modBlacklist[v:lower()] = true
	end
	for _, v in pairs(config.npcBlacklist) do
		npcBlacklist[v:lower()] = true
	end
	mwse.log("Blacklists:\nMods: %s\nNPCs: %s", json.encode(modBlacklist), json.encode(npcBlacklist))

	-- Go through and resolve our robes.
	for k, _ in pairs(robes) do
		robes[k] = tes3.getObject(k)
	end

	-- Hit all the NPCs and give them new robes.
	for npc in tes3.iterateObjects(tes3.objectType.npc) do
		if (not npc.isInstance) then
			local qualifies, newRobe, oldRobe = getRobeForNPC(npc)
			if (qualifies) then
				-- local highestSkill, highestSkillValue = getHighestMagicSkill(npc)
				-- mwse.log("Replacing robes for %s (%s). %s -> %s. Faction: %s (%s). Highest skill: %s (%d)", npc.id, npc.sourceMod, oldRobe and oldRobe.id, newRobe.id, npc.faction.id, table.find(mgRank, npc.factionRank), table.find(tes3.skill, highestSkill), highestSkillValue)
				npc.inventory:addItem({ item = newRobe })
				if (oldRobe) then
					npc.inventory:removeItem({ item = oldRobe })
				end
			end
		end
	end
end
event.register("initialized", onInitialized)
