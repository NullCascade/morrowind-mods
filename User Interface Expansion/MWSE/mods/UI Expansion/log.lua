local logger = require("logging.logger")
local config = require("UI Expansion.config")

return logger.new({
	name = "UI Expansion",
	logLevel = config.logLevel,
	logToConsole = false,
	includeTimestamp = true,
})