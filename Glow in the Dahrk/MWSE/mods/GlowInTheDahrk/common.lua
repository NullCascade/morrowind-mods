local common = {}

common.log = require("logging.logger").new({
	name = "Glow in the Dahrk",
})

common.i18n = mwse.loadTranslations("GlowInTheDahrk")

return common
