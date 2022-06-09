local config = require("GlowInTheDahrk.config")
local interop = require("GlowInTheDahrk.interop")
local common = require("GlowInTheDahrk.common")
local i18n = common.i18n

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Glow in the Dahrk", headerImagePath = "textures/GITD_Header.dds" })
	template:saveOnClose("Glow in the Dahrk", config)

	local preferences = template:createSideBarPage({ label = "Preferences" })
	preferences.sidebar:createInfo({
		text = i18n("mcm.info"),
	})

	preferences:createOnOffButton({
		label = i18n("mcm.useVariance.label"),
		description = i18n("mcm.useVariance.description"),
		variable = mwse.mcm:createTableVariable({ id = "useVariance", table = config }),
	})

	preferences:createSlider({
		label = i18n("mcm.varianceInMinutes.label"),
		description = i18n("mcm.varianceInMinutes.description"),
		min = 1,
		max = 240,
		step = 5,
		jump = 15,
		variable = mwse.mcm:createTableVariable({ id = "varianceInMinutes", table = config }),
	})

	preferences:createOnOffButton({
		label = i18n("mcm.addInteriorSunrays.label"),
		description = i18n("mcm.addInteriorSunrays.description"),
		variable = mwse.mcm:createTableVariable({ id = "addInteriorSunrays", table = config }),
		callback = interop.resetConfigurableStateForAllReferences,
	})

	preferences:createOnOffButton({
		label = i18n("mcm.addInteriorLights.label"),
		description = i18n("mcm.addInteriorLights.description"),
		variable = mwse.mcm:createTableVariable({ id = "addInteriorLights", table = config }),
		callback = interop.resetConfigurableStateForAllReferences,
	})

	preferences:createDropdown({
		label = i18n("mcm.logLevel.label"),
		description = i18n("mcm.logLevel.description"),
		options = {
			{ label = i18n("mcm.logLevel.TRACE"), value = "TRACE" },
			{ label = i18n("mcm.logLevel.DEBUG"), value = "DEBUG" },
			{ label = i18n("mcm.logLevel.INFO"), value = "INFO" },
			{ label = i18n("mcm.logLevel.ERROR"), value = "ERROR" },
			{ label = i18n("mcm.logLevel.NONE"), value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
		callback = function(self)
			common.log:setLogLevel(self.variable.value)
		end
	})

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
