
local config = require("Consistent Enchanting.config")

local function saveConfig()
	mwse.saveConfig("Consistent Enchanting", config)
end

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Consistent Enchanting" })
	template:saveOnClose("Consistent Enchanting", config)

	-- Preferences Page
	do
		local preferences = template:createSideBarPage({ label = "Preferences" })
		preferences.sidebar:createInfo({
			text = "Consistent Enchanting v1.1\n\nCreated by NullCascade.\n\nMouse over a feature for more info."
		})

		-- Feature Toggles
		preferences:createOnOffButton({
			label = "Preserve base object?",
			description = "If enabled, the lowercased ID of the item used to make the newly enchanted item is stored in the new item's lua data. It can be accessed using the ncceEnchantedFrom field.\n\nThis allows other mods to access this data if it is available.\n\nIt is not advised that you disable this.",
			variable = mwse.mcm:createTableVariable({
				id = "storeBaseObject",
				table = config,
			}),
		})
		preferences:createOnOffButton({
			label = "Preserve soul used?",
			description = "If enabled, the lowercased ID of the soul used to make the newly enchanted item is stored in the new item's lua data. It can be accessed using the ncceEnchantedSoul field.\n\nThis allows other mods to access this data if it is available.\n\nIt is not advised that you disable this.",
			variable = mwse.mcm:createTableVariable({
				id = "storeBaseObject",
				table = config,
			}),
		})
		preferences:createOnOffButton({
			label = "Preserve condition?",
			description = "If enabled, the newly enchanted item's condition will match the item used to create it.",
			variable = mwse.mcm:createTableVariable({
				id = "condition",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = "Preserve script?",
			description = "If enabled, the newly enchanted item will use the same script as the item used to create it.",
			variable = mwse.mcm:createTableVariable({
				id = "script",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = "Preserve script data?",
			description = "If enabled, all mwscript variable values will be copied to the newly created item.\n\nThis will do nothing if script preserving is disabled.",
			variable = mwse.mcm:createTableVariable({
				id = "scriptData",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = "Preserve lua data?",
			description = "If enabled, all lua data stored on the old item will be copied over to the newly enchanted item.",
			variable = mwse.mcm:createTableVariable({
				id = "luaData",
				table = config.copy,
			}),
		})
		preferences:createOnOffButton({
			label = "Preserve temporary lua data?",
			description = "If enabled, all temporary lua data stored on the old item will be copied over to the newly enchanted item.",
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
