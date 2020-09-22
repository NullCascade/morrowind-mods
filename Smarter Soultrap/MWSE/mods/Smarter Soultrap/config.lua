local config = mwse.loadConfig("Smarter Soultrap", {
	displacement = true,
	relocation = true,
	leveling = false,
	levelingSkill = "mysticism",
	levelRequirements = {
		displacement = 25,
		relocation = 50,
	},
	showSoultrapMessage = true,
	showDisplacementMessage = true,
	showRelocationMessage = true,
})

-- Do some basic validation.
assert(tes3.skill[config.levelingSkill], "Invalid leveling skill provided.")

return config