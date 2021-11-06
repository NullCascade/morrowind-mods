
local config = require("Expeditious Exit.config")

--- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Expeditious Exit" })
	template:saveOnClose("Expeditious Exit", config)

	local page = template:createSideBarPage()
	page.sidebar:createInfo({
		text = "Expeditious Exit v1.3\nby NullCascade",
	})

	page:createOnOffButton({
		label = "Display confirmation message box?",
		description = "If enabled, the vanilla confirmation box will be shown to ask if you wish to exit the game.",
		variable = mwse.mcm.createTableVariable({ id = "showMenuOnExit", table = config }),
	})

	page:createOnOffButton({
		label = "Allow alt-F4?",
		description = "If enabled, the combination of alt-F4 will close the game without a prompt. Not all users may require this.",
		variable = mwse.mcm.createTableVariable({ id = "allowAltF4", table = config }),
	})

	page:createOnOffButton({
		label = "Use taskkill?",
		description = "If using certain 3rd party hooks, like DXVK, the typical closing method can fail. If so, this will be more reliable.",
		variable = mwse.mcm.createTableVariable({ id = "useTaskKill", table = config }),
	})

	template:register()
end
event.register("modConfigReady", registerModConfig)
