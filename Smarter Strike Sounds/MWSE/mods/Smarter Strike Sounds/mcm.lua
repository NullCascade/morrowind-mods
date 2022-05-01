local config = require("Smarter Strike Sounds.config")

--- Setup MCM.
local function registerModConfig()
	local i18n = mwse.loadTranslations("Smarter Strike Sounds")

	local template = mwse.mcm.createTemplate({ name = i18n("core.modName") })
	template:saveOnClose("Smarter Strike Sounds", config)

	local page = template:createSideBarPage({ label = "Wee?" })
	page.sidebar:createInfo({ text = i18n("core.modName") .. " " .. i18n("core.versionString") .. "\n" .. i18n("core.credits") .. "\n\n" .. i18n("mcm.about") })

	page:createOnOffButton({
		label = i18n("mcm.doNotRepeatStrikeSounds.label"),
		description = i18n("mcm.doNotRepeatStrikeSounds.description"),
		variable = mwse.mcm.createTableVariable({ id = "doNotRepeatStrikeSounds", table = config }),
	})

	page:createOnOffButton({
		label = i18n("mcm.playRandomEffectSound.label"),
		description = i18n("mcm.playRandomEffectSound.description"),
		variable = mwse.mcm.createTableVariable({ id = "playRandomEffectSound", table = config }),
	})

	-- Finish up.
	template:register()
end

event.register("modConfigReady", registerModConfig)
