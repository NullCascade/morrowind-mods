local config = mwse.loadConfig("Smarter Soultrap", {
	logLevel = "INFO",
	displacement = true,
	relocation = true,
	leveling = true,
	levelingSkill = "mysticism",
	levelRequirements = {
		displacement = 50,
		relocation = 75,
	},
	showSoultrapMessage = true,
	showDisplacementMessage = true,
	showRelocationMessage = true,
})

-- Do some basic validation.
assert(tes3.skill[config.levelingSkill], "Invalid leveling skill provided.")

return config