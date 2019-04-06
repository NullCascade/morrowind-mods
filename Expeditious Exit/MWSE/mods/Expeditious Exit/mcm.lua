
local config = require("Expeditious Exit.config")

local function saveConfig()
	mwse.saveConfig("Expeditious Exit", config)
end

local easyMCMConfig = {
	name = "Expeditious Exit",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Display confirmation message box?",
					class = "OnOffButton",
					description = "If enabled, the vanilla confirmation box will be shown to ask if you wish to exit the game.",
					variable = {
						id = "showMenuOnExit",
						class = "TableVariable",
						table = config,
					},
				},
			},
			sidebarComponents = {
				{
					label = "Mod Description",
					class = "Info",
					text = "This mod will force-exit the game when the exit button is pressed, preventing the game from hanging.",
				},
			},
		},
	},
	onClose = saveConfig,
}

return easyMCMConfig
