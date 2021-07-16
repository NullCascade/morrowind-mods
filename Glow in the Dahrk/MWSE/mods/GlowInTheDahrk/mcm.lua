
local config = require("GlowInTheDahrk.config")

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Glow in the Dahrk", headerImagePath = "textures/GITD_Header.dds" })
	template:saveOnClose("Glow in the Dahrk", config)

	local preferences = template:createSideBarPage({ label = "Preferences" })
	preferences.sidebar:createInfo({
		text = "Glow in the Dahrk\n\nModels and textures by Melchior Dahrk\nScripting by NullCascade.\n\nMouse over a feature for more info."
	})

	preferences:createOnOffButton({
		label = "Stagger exterior transitions?",
		description = "This can look unnatural on small buildings with multiple windows. But with it turned off, all windows will light up/go dark at the same time.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable({ id = "useVariance", table = config }),
	})

	preferences:createSlider({
		label = "Maximum stagger (in minutes)",
		description = "The amount of time before or after dawn/dusk that an exterior object can have its lighting changed. A value of 30 means that windows can light up 30 minutes earlier or later than the norm.\n\nDefault: 30",
		min = 1,
		max = 240,
		step = 5,
		jump = 15,
		variable = mwse.mcm:createTableVariable({ id = "varianceInMinutes", table = config }),
	})

	preferences:createOnOffButton({
		label = "Add sunrays to interiors?",
		description = "When enabled, sunrays will be added around windows when they are lit from the outside.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable({ id = "addInteriorSunrays", table = config }),
	})

	preferences:createOnOffButton({
		label = "Add interior lights to windows?",
		description = "When enabled, light will be added around windows when they are lit from the outside.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable({ id = "addInteriorLights", table = config }),
	})
	
	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
