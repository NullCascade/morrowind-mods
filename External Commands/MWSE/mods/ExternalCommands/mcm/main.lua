local config = require("ExternalCommands.config")

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "External Commands" })
	template:saveOnClose("External Commands", config)

	local page = template:createSideBarPage()
	page.sidebar:createInfo({ text = "External Commands\nv1.0\nby NullCascade\n\n" })

	page:createOnOffButton({
		label = "Enable file monitoring?",
		description = "...",
		variable = mwse.mcm.createTableVariable({ id = "enableFileMonitoring", table = config }),
	})

	page:createTextField({
		label = "Dictory:",
		description = "...",
		variable = mwse.mcm.createTableVariable({
			id = "commandDir",
			table = config,
		}),
	})

	page:createOnOffButton({
		label = "Enable TCP connections?",
		description = "...",
		variable = mwse.mcm.createTableVariable({ id = "enableNetworking", table = config }),
	})

	page:createTextField({
		label = "Port:",
		description = "The port to use when monitoring connections.",
		variable = mwse.mcm.createTableVariable({
			id = "tcpPort",
			table = config,
			numbersOnly = true,
		}),
	})

	-- Finish up.
	template:register()
end

event.register("modConfigReady", registerModConfig)
