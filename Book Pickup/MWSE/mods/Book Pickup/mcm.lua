
local config = require("Book Pickup.config")
local i18n = require("Book Pickup.i18n")

local function registerModConfig()
	local mcm = mwse.mcm

	local template = mcm.createTemplate(i18n("core.modName"))
	template:saveOnClose("Book Pickup", config)

	local page = template:createSideBarPage({ label = "foo" })
	page.sidebar:createInfo({
		text = i18n("core.modName") .. " " .. i18n("core.versionString") .. "\n\n" .. i18n("mcm.credits"),
	})

	page:createOnOffButton({
		label = i18n("mcm.pickupByDefault.label"),
		description = i18n("mcm.pickupByDefault.description"),
		variable = mwse.mcm.createTableVariable({ id = "pickupByDefault", table = config }),
	})

	page:createOnOffButton({
		label = i18n("mcm.checkOwnership.label"),
		description = i18n("mcm.checkOwnership.description"),
		variable = mwse.mcm.createTableVariable({ id = "checkOwnership", table = config }),
	})

	template:register()
end
event.register("modConfigReady", registerModConfig)
