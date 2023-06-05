local config = require("Visually Filled Soul Gems.config")
return require("logging.logger").new({
    name = "Visually Filled Soul Gems",
    logLevel = config.logLevel,
    logToConsole = true,
    includeTimestamp = true,
})
