return mwse.loadConfig("Wonders of Water", {
	enabled = true,
	features = {
		sunDamage = true,
		waterCaustics = true,
		waterClarity = true,
		waterWaves = true,
	},
	-- regions = {
		-- TODO
	-- },
	weathers = {
		clear = {
			caustics = 0.2,
			clarity = 1.0,
			waveHeight = 0.2,
		},
		cloudy = {
			caustics = 0.4,
			clarity = 1.0,
			waveHeight = 0.4,
		},
		foggy = {
			caustics = 0.1,
			clarity = 1.0,
			waveHeight = 0.1,
		},
		overcast = {
			caustics = 0.4,
			clarity = 1.0,
			waveHeight = 0.4,
		},
		rain = {
			caustics = 1.2,
			clarity = 1.0,
			waveHeight = 1.2,
		},
		thunder = {
			caustics = 2.0,
			clarity = 1.0,
			waveHeight = 2.0,
		},
		ash = {
			caustics = 1.5,
			clarity = 1.0,
			waveHeight = 1.5,
		},
		blight = {
			caustics = 1.8,
			clarity = 1.0,
			waveHeight = 1.8,
		},
		snow = {
			caustics = 0.2,
			clarity = 1.0,
			waveHeight = 0.2,
		},
		blizzard = {
			caustics = 0.5,
			clarity = 1.0,
			waveHeight = 0.5,
		},
	}
})
