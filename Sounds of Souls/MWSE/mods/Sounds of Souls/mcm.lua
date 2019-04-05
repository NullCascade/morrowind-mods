
local config = require("Sounds of Souls.config")

mwse.log("[nc-sos] Loaded config:\n%s", json.encode(config))

local function saveConfig()
	mwse.saveConfig("Sounds of Souls", config)
end

local function setSliderLabelAsPercentage(self)
	self.elements.sliderValueLabel.text = ( ": " .. self.elements.slider.widget.current + self.min .. "%" )
end

local function setSliderLabelAsSeconds(self)
	self.elements.sliderValueLabel.text = ( ": " .. self.elements.slider.widget.current + self.min .. " seconds" )
end

local easyMCMConfig = {
	name = "Sounds of Souls",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Environmental Checks",
					class = "Category",
					components = {
						{
							label = "Activated Soulgems",
							class = "Category",
							components = {
								{
									label = "Enabled",
									class = "OnOffButton",
									description = "If enabled, there is a chance for a sound to play when activating a filled soul gem.",
									variable = {
										id = "enabled",
										class = "TableVariable",
										table = config.environmentChecks.activate,
									},
								},
								{
									label = "Chance",
									class = "Slider",
									description = "Changes the chance of a soul to cause a sound on activation.",
									min = 1,
									max = 100,
									step = 1,
									jump = 5,
									variable = {
										id = "chance",
										class = "TableVariable",
										table = config.environmentChecks.activate,
									},
									postCreate = setSliderLabelAsPercentage,
									updateValueLabel = setSliderLabelAsPercentage,
								},
							},
						},
						{
							label = "Soulgems in Current Cell",
							class = "Category",
							components = {
								{
									label = "Enabled",
									class = "OnOffButton",
									description = "If enabled, there is a chance for a sound to play randomly from items in the current cell.",
									variable = {
										id = "enabled",
										class = "TableVariable",
										table = config.environmentChecks.cell,
									},
								},
								{
									label = "Chance",
									class = "Slider",
									description = "Changes the chance of a soul to cause a sound on activation.",
									min = 1,
									max = 100,
									step = 1,
									jump = 5,
									variable = {
										id = "chance",
										class = "TableVariable",
										table = config.environmentChecks.cell,
									},
									postCreate = setSliderLabelAsPercentage,
									updateValueLabel = setSliderLabelAsPercentage,
								},
								{
									label = "Minimum Frequency",
									class = "Slider",
									description = "The minimum amount of time between checks to see if a sound should be played.",
									min = 1,
									max = 300,
									step = 1,
									jump = 5,
									variable = {
										id = "timerMin",
										class = "TableVariable",
										table = config.environmentChecks.cell,
									},
									postCreate = setSliderLabelAsSeconds,
									updateValueLabel = setSliderLabelAsSeconds,
								},
								{
									label = "Maximum Frequency",
									class = "Slider",
									description = "The maximum amount of time between checks to see if a sound should be played.",
									min = 1,
									max = 300,
									step = 1,
									jump = 5,
									variable = {
										id = "timerMax",
										class = "TableVariable",
										table = config.environmentChecks.cell,
									},
									postCreate = setSliderLabelAsSeconds,
									updateValueLabel = setSliderLabelAsSeconds,
								},
							},
						},
						{
							label = "Soulgems in Player Inventory",
							class = "Category",
							components = {
								{
									label = "Enabled",
									class = "OnOffButton",
									description = "If enabled, there is a chance for a sound to play randomly from items in the player's inventory.",
									variable = {
										id = "enabled",
										class = "TableVariable",
										table = config.environmentChecks.playerInventory,
									},
								},
								{
									label = "Chance",
									class = "Slider",
									description = "Changes the chance of a soul to cause a sound on activation.",
									min = 1,
									max = 100,
									step = 1,
									jump = 5,
									variable = {
										id = "chance",
										class = "TableVariable",
										table = config.environmentChecks.playerInventory,
									},
									postCreate = setSliderLabelAsPercentage,
									updateValueLabel = setSliderLabelAsPercentage,
								},
								{
									label = "Minimum Frequency",
									class = "Slider",
									description = "The minimum amount of time between checks to see if a sound should be played.",
									min = 1,
									max = 300,
									step = 1,
									jump = 5,
									variable = {
										id = "timerMin",
										class = "TableVariable",
										table = config.environmentChecks.playerInventory,
									},
									postCreate = setSliderLabelAsSeconds,
									updateValueLabel = setSliderLabelAsSeconds,
								},
								{
									label = "Maximum Frequency",
									class = "Slider",
									description = "The maximum amount of time between checks to see if a sound should be played.",
									min = 1,
									max = 300,
									step = 1,
									jump = 5,
									variable = {
										id = "timerMax",
										class = "TableVariable",
										table = config.environmentChecks.playerInventory,
									},
									postCreate = setSliderLabelAsSeconds,
									updateValueLabel = setSliderLabelAsSeconds,
								},
							},
						},
					},
				},
				{
					label = "Volume",
					class = "Category",
					components = {
						{
							label = "Minimum Volume",
							class = "Slider",
							description = "When volume is determined, it is between these two values, then multipled by Value Scaler.",
							min = 0,
							max = 100,
							step = 1,
							jump = 5,
							variable = {
								id = "min",
								class = "TableVariable",
								table = config.volume,
							},
							postCreate = setSliderLabelAsPercentage,
							updateValueLabel = setSliderLabelAsPercentage,
						},
						{
							label = "Maximum Volume",
							class = "Slider",
							description = "When volume is determined, it is between these two values, then multipled by Value Scaler.",
							min = 0,
							max = 200,
							step = 1,
							jump = 5,
							variable = {
								id = "max",
								class = "TableVariable",
								table = config.volume,
							},
							postCreate = setSliderLabelAsPercentage,
							updateValueLabel = setSliderLabelAsPercentage,
						},
					},
				},
				{
					label = "Pitch",
					class = "Category",
					components = {
						{
							label = "Minimum Pitch",
							class = "Slider",
							description = "When pitch is determined, it is between these two values, then multipled by Value Scaler.",
							min = 1,
							max = 200,
							step = 1,
							jump = 5,
							variable = {
								id = "min",
								class = "TableVariable",
								table = config.pitch,
							},
							postCreate = setSliderLabelAsPercentage,
							updateValueLabel = setSliderLabelAsPercentage,
						},
						{
							label = "Maximum Pitch",
							class = "Slider",
							description = "When pitch is determined, it is between these two values, then multipled by Value Scaler.",
							min = 1,
							max = 200,
							step = 1,
							jump = 5,
							variable = {
								id = "max",
								class = "TableVariable",
								table = config.pitch,
							},
							postCreate = setSliderLabelAsPercentage,
							updateValueLabel = setSliderLabelAsPercentage,
						},
					},
				},
			},
			sidebarComponents = {
				{
					label = "Mod Description",
					class = "Info",
					text = "Ever think that it's a bit creepy that there are souls trapped just there, on your desk? Would it be even creepier if the souls spoke from beyond the grave? This mod makes them do just that!\n\nSoul gems in the world, in the player's inventory, and that the player interacts with will play sounds, corresponding to the creature trapped inside of it. This includes creatures added by mods.",
				},
			},
		},
	},
	onClose = saveConfig,
}

return easyMCMConfig
