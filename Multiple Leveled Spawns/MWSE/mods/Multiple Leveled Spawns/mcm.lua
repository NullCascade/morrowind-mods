
local config = require("Multiple Leveled Spawns.config")
local log = require("Multiple Leveled Spawns.log")

local function onModConfigReady()
	local template = mwse.mcm.createTemplate({ name = "Multiple Leveled Spawns" })
	template:saveOnClose("Multiple Leveled Spawns", config)
	template:register()

	local pageSettings = template:createSideBarPage({ label = "Settings" })
	pageSettings.sidebar:createCategory("Multiple Leveled Spawns")
	pageSettings.sidebar:createInfo({ text = "v1.0\n\nAllows a leveled creature spawner to potentially spawn more than one creature." })

	pageSettings:createYesNoButton({
		label = "Enable mod?",
		description = "This setting lets you temporarily disable the mod without having to uninstall it.",
		variable = mwse.mcm.createTableVariable{ id = "enabled", table = config },
	})

	pageSettings:createPercentageSlider({
		label = "Chance of additional spawn",
		description = "The chance of an additional spawn being created. If a spawn is created, this will be rolled again, repeating the process until the maximum number of spawns is reached. Note that each leveled list has an innate chance to spawn nothing, which further modifies this probability.",
		variable = mwse.mcm.createTableVariable{ id = "chanceOfAdditionalSpawn", table = config },
	})

	pageSettings:createTextField({
		label = "Maximum number of spawns",
		description = "The limit before no more spawns will be created.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{ id = "maxSpawns", table = config, converter = tonumber },
	})

	pageSettings:createDropdown({
		label = "Log Level",
		description = "Set the logging level for Multiple Leveled Spawns in mwse.log.",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable =  mwse.mcm.createTableVariable({ id = "logLevel", table = config }),
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end,
	})
end
event.register(tes3.event.modConfigReady, onModConfigReady)
