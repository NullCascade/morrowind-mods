local logger = require("logging.logger")
local config = require("Smarter Soultrap.config")

return logger.new({
	name = "Smarter Soultrap",
	logLevel = config.logLevel,
	logToConsole = false,
	includeTimestamp = true,
})
