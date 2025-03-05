local logger = require("logging.logger")
local config = require("Multiple Leveled Spawns.config")

return logger.new({
	name = "Multiple Leveled Spawns",
	logLevel = config.logLevel,
	logToConsole = false,
	includeTimestamp = false,
})