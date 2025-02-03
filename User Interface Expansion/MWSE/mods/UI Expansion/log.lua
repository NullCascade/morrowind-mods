local logger = require("logging.logger")

return logger.new({
	name = "UI Expansion",
	logLevel = "INFO",
	logToConsole = false,
	includeTimestamp = true,
})