
local config = require("Wonders of Water.config")
local interop = require("Wonders of Water.interop")

local function getSortedWeatherList()
	local weathers = {} --- @type tes3weather[]
	for _, weather in ipairs(tes3.worldController.weatherController.weathers) do
		table.insert(weathers, weather)
	end

	table.sort(weathers, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	return weathers
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Wonders of Water" })

	-- Save config options when the mod config menu is closed
	template:saveOnClose("Wonders of Water", config)

	-- Create a simple container Page under Template
	do
		local settings = template:createPage({ label = "Settings" })

		-- Create a button under Page that toggles a variable between true and false
		settings:createYesNoButton({
			label = "Enable Mod",
			variable = mwse.mcm:createTableVariable({ id = "enabled", table = config }),
			callback = interop.resetValues
		})

		local features = settings:createCategory({ label = "Features" })
		do
			features:createYesNoButton({
				label = "Reduce sun damage in the depths?",
				variable = mwse.mcm:createTableVariable({ id = "sunDamage", table = config.features }),
			})

			features:createYesNoButton({
				label = "Use weather-based water caustics?",
				variable = mwse.mcm:createTableVariable({ id = "waterCaustics", table = config.features }),
			})

			features:createYesNoButton({
				label = "Use weather-based water wave height?",
				variable = mwse.mcm:createTableVariable({ id = "waterWaves", table = config.features }),
			})

			features:createYesNoButton({
				label = "Use depth-based water clarity?",
				variable = mwse.mcm:createTableVariable({ id = "waterClarity", table = config.features }),
			})
		end
	end

	-- Create a simple container Page under Template
	do
		local weathers = template:createPage({ label = "Weathers" })

		local allWeathers = getSortedWeatherList()
		for _, weather in ipairs(allWeathers) do
			local category = weathers:createCategory({ label = weather.name })
			local weatherConfig = interop.getConfigForWeather(weather)
			category:createTextField({
				label = "Caustics Multiplier",
				description = "A multiplier applied to water caustics when this weather is active.",
				variable = mwse.mcm.createTableVariable({ id = "caustics", converter = tonumber, table = weatherConfig }),
				numbersOnly = true,
			})
			category:createTextField({
				label = "Wave Height Multiplier",
				description = "A multiplier applied to wave heights when this weather is active.",
				variable = mwse.mcm.createTableVariable({ id = "waveHeight", converter = tonumber, table = weatherConfig }),
				numbersOnly = true,
			})
			category:createTextField({
				label = "Clarity Multiplier",
				description = "A multiplier applied to visibility when underwater during this weather.",
				variable = mwse.mcm.createTableVariable({ id = "clarity", converter = tonumber, table = weatherConfig }),
				numbersOnly = true,
			})
		end
	end

	-- Finish up.
	template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)
