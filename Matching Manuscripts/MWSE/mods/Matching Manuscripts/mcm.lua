
local config = require("Matching Manuscripts.config")

local function saveConfig()
	mwse.saveConfig("Matching Manuscripts", config)
end

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Matching Manuscripts" })
	template:saveOnClose("Matching Manuscripts", config)

	-- Preferences Page
	do
		local preferences = template:createSideBarPage({ label = "Preferences" })
		preferences.sidebar:createInfo({
			text = "Matching Manuscripts v1.0\n\nCreated by NullCascade and RedFurryDemon.\n\nMouse over a feature for more info."
		})

		-- Feature Toggles
		preferences:createOnOffButton({
			label = "Enable mod?",
			description = "This provides a quick option to toggle the mod on or off.",
			variable = mwse.mcm:createTableVariable({
				id = "enabled",
				table = config,
			}),
		})
	end
	
	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
