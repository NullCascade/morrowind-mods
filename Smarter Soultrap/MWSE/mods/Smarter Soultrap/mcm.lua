
local config = require("Smarter Soultrap.config")

local function saveConfig()
	mwse.saveConfig("Smarter Soultrap", config)
end

local easyMCMConfig = {
	name = "Smarter Soultrap",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Allow soul displacement?",
					class = "OnOffButton",
					description = "Displacement allows soultrap to replace a soul in a soulgem if no empty soulgem was found.\n\nFor example if the player has a single Grand Soul Gem that is currently occupied by a rat, the player may still soultrap a Golden Saint, who will replace the rat in the soulgem.",
					variable = {
						id = "displacement",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Allow soul relocation?",
					class = "OnOffButton",
					description = "When a soul is displaced, relocation allows it to find a new home\n\nFor example, if the player has a Grand Soul Gem filled with a rat, and an empty Petty Soul Gem, they may soultrap a Golden Saint. Displacement will move the rat soul out of the soulgem, replacing it with the Golden Saint. Relocation then moves the soul to the Petty Soul Gem\n\nThis process can repeat, chaining displaced souls until everything has a suitable home.\n\nNote: This requires soul displacement to be enabled.",
					variable = {
						id = "relocation",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Enforce skill requirements?",
					class = "OnOffButton",
					description = "When enabled, level requirements disable certain features if the player's skill is not high enough.\n\nThe skill checked and the individual values must be edited in the config file.",
					variable = {
						id = "leveling",
						class = "TableVariable",
						table = config,
					},
				},
			},
			sidebarComponents = {
				{
					label = "Smarter Soultrap",
					class = "Info",
					text = "This mod aims to improve the soultrap mechanic with the following features:\n\nDisplacement: Given no other viable soulgem, souls will kick out weaker ones and take their place.\n\nRelocation: A soul displaced can find a new home in another soulgem.\n\nSmarter Soultrap is inspired by Genuinely Intelligent Soul Trap by opusGlass.",
				},
			},
		},
	},
	onClose = saveConfig,
}

return easyMCMConfig
