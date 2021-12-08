local config = mwse.loadConfig("Glow in the Dahrk", {
	varianceInMinutes = 30,
	useVariance = false,
	addInteriorLights = true,
	addInteriorSunrays = true,
})

-- Remove legacy values.
config.cellData = nil

return config