local config = require("Unlock Overhaul.config")

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Unlock Overhaul" })
	template:saveOnClose("Unlock Overhaul", config)

	local basePageInfo = "Unlock Overhaul v1.0\nby NullCascade.\n\n"
	local moreInfoText = "\n\nMouse over a feature for more info."

	-- Page: Settings
	do
		local page = template:createSideBarPage({ label = "Settings" })
		page.sidebar:createInfo({ text = basePageInfo .. "This mod allows modders to take more control over how keys are used. It also allows the Skeleton Key to function as a universal key." .. moreInfoText })
		page:createOnOffButton({
			label = "Key use bypasses traps?",
			description = "When on, using a key automatically bypasses traps. This is vanilla behavior.",
			variable = mwse.mcm.createTableVariable({ id = "keyBypassesTraps", table = config }),
		})
		page:createOnOffButton({
			label = "Skeleton Key is a universal key?",
			description = "When on, the Skeleton Key will substitute any key. This will however only work on lock levels above 0.",
			variable = mwse.mcm.createTableVariable({ id = "allowSkeletonKey", table = config }),
		})
		page:createOnOffButton({
			label = "Skeleton Key bypasses traps?",
			description = "When on and when Skeleton Key use is enabled, the Skeleton key will bypass traps.",
			variable = mwse.mcm.createTableVariable({ id = "allowSkeletonKey", table = config }),
		})
	end

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
