
local config = require("Consistent Enchanting.config")
local i18n = require("Consistent Enchanting.i18n")
local metadata = tes3.getLuaModMetadata("Consistent Enchanting")

local function registerModConfig()
	local template = mwse.mcm.createTemplate(i18n("core.modName"))
	template:saveOnClose("Consistent Enchanting", config)

	-- Preferences Page
	do
		local preferences = template:createSideBarPage({ label = "Preferences" })
		preferences.sidebar:createInfo({
			text = i18n("core.modDescription", { metadata.package.version }),
		})

		-- Feature Toggles
		preferences:createOnOffButton({
			label = i18n("mcm.storeBaseObject.label"),
			description = i18n("mcm.storeBaseObject.description"),
			variable = mwse.mcm:createTableVariable({
				id = "storeBaseObject",
				table = config,
			}),
		})
		preferences:createOnOffButton({
			label = i18n("mcm.storeSoulUsed.label"),
			description = i18n("mcm.storeSoulUsed.description"),
			variable = mwse.mcm:createTableVariable({
				id = "storeSoulUsed",
				table = config,
			}),
		})
		preferences:createOnOffButton({
			label = i18n("mcm.copy.condition.label"),
			description = i18n("mcm.copy.condition.description"),
			variable = mwse.mcm:createTableVariable({
				id = "condition",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = i18n("mcm.copy.script.label"),
			description = i18n("mcm.copy.script.description"),
			variable = mwse.mcm:createTableVariable({
				id = "script",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = i18n("mcm.copy.scriptData.label"),
			description = i18n("mcm.copy.scriptData.description"),
			variable = mwse.mcm:createTableVariable({
				id = "scriptData",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = i18n("mcm.copy.luaData.label"),
			description = i18n("mcm.copy.luaData.description"),
			variable = mwse.mcm:createTableVariable({
				id = "luaData",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = i18n("mcm.copy.luaTempData.label"),
			description = i18n("mcm.copy.luaTempData.description"),
			variable = mwse.mcm:createTableVariable({
				id = "luaTempData",
				table = config.copy,
			}),
		})
	end

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
