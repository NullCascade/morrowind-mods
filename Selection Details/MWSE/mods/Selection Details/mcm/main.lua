local config = require("Selection Details.config")

local function registerModConfig()
	local i18n = require("Selection Details.i18n")

	local template = mwse.mcm.createTemplate({ name = i18n("core.modName") })
	template:saveOnClose("Selection Details", config)

	local page = template:createSideBarPage()
	page.sidebar:createInfo({ text = i18n("core.modName") .. " " .. i18n("core.versionString") .. "\n" .. i18n("core.credits") .. "\n\n" .. i18n("mcm.about") })

	page:createOnOffButton({
		label = i18n("mcm.requireControlKey.label"),
		description = i18n("mcm.requireControlKey.description"),
		variable = mwse.mcm.createTableVariable({ id = "requireControlKey", table = config }),
	})

	-- Finish up.
	template:register()
end

event.register("modConfigReady", registerModConfig)
