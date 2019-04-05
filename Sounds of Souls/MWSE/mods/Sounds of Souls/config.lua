local config = mwse.loadConfig("Sounds of Souls")

if (config == nil or config.environmentChecks.activate.enabled == nil) then
	config = {
		environmentChecks = {
			activate = {
				enabled = true,
				chance = 75,
			},
			cell = {
				enabled = true,
				timerMin = 1,
				timerMax = 60,
				chance = 20,
			},
			playerInventory = {
				enabled = true,
				timerMin = 30,
				timerMax = 90,
				chance = 50,
			}
		},
		volume = {
			max = 75,
			soulValueScaler = 5,
			min = 10,
		},
		pitch = {
			max = 110,
			soulValueScaler = 5,
			min = 90,
		},
	}
end

return config