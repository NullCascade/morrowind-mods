local config = require("Matching Manuscripts.config")
local i18n = require("Matching Manuscripts.i18n")

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = i18n("core.modName") })
	template:saveOnClose("Matching Manuscripts", config)

	-- Preferences Page
	do
		local preferences = template:createSideBarPage()
		preferences.sidebar:createInfo({
			text = string.format("%s %s\n\n%s\n\n%s", i18n("core.modName"), i18n("core.versionString"), i18n("core.about"), i18n("core.credits"))
		})

		-- Feature Toggles
		preferences:createOnOffButton({
			label = i18n("mcm.enabled.label"),
			description = i18n("mcm.enabled.description"),
			variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
		})
	end

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
