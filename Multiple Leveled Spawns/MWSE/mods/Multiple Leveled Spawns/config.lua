
--- @class MultipleLeveledSpawns.config
--- @field enabled boolean
--- @field logLevel string
--- @field chanceOfAdditionalSpawn number
--- @field maxSpawns number

--- @type MultipleLeveledSpawns.config
local defaultConfig = {
	logLevel = "INFO",
	enabled = true,
	chanceOfAdditionalSpawn = 0.25,
	maxSpawns = 3,
}

--- @type MultipleLeveledSpawns.config
local config = mwse.loadConfig("Multiple Leveled Spawns", defaultConfig) or defaultConfig

-- Config validation.
config.chanceOfAdditionalSpawn = math.clamp(config.chanceOfAdditionalSpawn, 0.0, 1.0)
config.maxSpawns = tonumber(config.maxSpawns)

return config