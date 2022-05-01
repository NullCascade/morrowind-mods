local config = require("Less Lame Leveled Spawns.config")

--- Setup MCM.
local function registerModConfig()
	local i18n = mwse.loadTranslations("Less Lame Leveled Spawns")

	local template = mwse.mcm.createTemplate({ name = i18n("core.modName") })
	template:saveOnClose("Less Lame Leveled Spawns", config)

	local page = template:createSideBarPage({ label = "Wee?" })
	page.sidebar:createInfo({ text = i18n("core.modName") .. " " .. i18n("core.versionString") .. "\n" .. i18n("core.credits") .. "\n\n" .. i18n("mcm.about") })

	page:createOnOffButton({
		label = i18n("mcm.blockSpawnsWhenLoading.label"),
		description = i18n("mcm.blockSpawnsWhenLoading.description"),
		variable = mwse.mcm.createTableVariable({ id = "blockSpawnsWhenLoading", table = config }),
	})

	page:createOnOffButton({
		label = i18n("mcm.blockSpawnsWithCooldown.label"),
		description = i18n("mcm.blockSpawnsWithCooldown.description"),
		variable = mwse.mcm.createTableVariable({ id = "blockSpawnsWithCooldown", table = config }),
	})

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
