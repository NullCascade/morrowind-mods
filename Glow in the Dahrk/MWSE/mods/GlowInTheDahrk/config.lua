return mwse.loadConfig("Glow in the Dahrk", {
	varianceInMinutes = 30,
	useVariance = false,
	addInteriorLights = true,
	addInteriorSunrays = true,
	cellOverrides = {
		profiles = {
			["Flip Interior Sources"] = {
				{ mesh = "^i\\in_*", data = { flipDayNightRole = true } },
			},
			["Flip Exterior Sources"] = {
				{ mesh = "^x\\ex_*", data = { flipDayNightRole = true } },
			},
		},
		definitions = {
			["Vivec, Foreign Quarter Plaza"] = { "Flip Exterior Sources" },
			["Vivec, Hlaalu Plaza"] = { "Flip Exterior Sources" },
			["Vivec, Redoran Plaza"] = { "Flip Exterior Sources" },
			["Vivec, Telvanni Plaza"] = { "Flip Exterior Sources" },
		},
	},
})
