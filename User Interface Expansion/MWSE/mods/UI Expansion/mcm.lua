local common = require("UI Expansion.common")
local externMapPlugin = include("uiexp_map_extension")

--- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "UI Expansion" })
	template:saveOnClose("UI Expansion", common.config)

	local creditsText = common.i18n("core.modName") .. " " .. common.i18n("core.versionString") .. "\n\n" ..
	                    common.i18n("mcm.credits") ..
	                    "\n  Programming: NullCascade, Hrnchamd, Petethegoat, Jiopsi, Remiros, Mort, Wix, abot, Necrolesian, Greatness7" ..
	                    "\n  Translations: Daichix, Fesswood, Monsterzeichner, and Google Translate" ..
	                    "\n  Concepts and Testing: Morrowind Modding Community Discord" ..
	                    "\n  Colored Magic School Icons: R-Zero" .. "\n  Inventory Filter Icons: Remiros" ..
	                    "\n  Training Skill Icons: RedFurryDemon" .. "\n  Value/Weight Ratio Icon: Necrolesian"

	-- Components section
	do
		local pageComponents = template:createSideBarPage({ label = common.i18n("mcm.tab.component") })
		pageComponents.sidebar:createInfo({
			text = creditsText .. "\n\nThe settings in this tab will not take affect until the next restart.",
		})

		local components = { "barter", "console", "contents", "dialog", "inventory", "inventorySelect", "magic", "magicSelect", "map", "mapPlugin", "options", "quantity", "rest", "saveLoad", "serviceSpells", "spellmaking", "stat", "textInput", "training" }
		for _, k in ipairs(components) do
			pageComponents:createOnOffButton({
				label = common.i18n(string.format("mcm.component.%s.label", k)),
				description = common.i18n(string.format("mcm.component.%s.description", k)),
				variable = mwse.mcm.createTableVariable({ id = k, table = common.config.components }),
			})
		end
	end

	-- Features setting
	do
		local pageFeatures = template:createSideBarPage({ label = common.i18n("mcm.tab.feature") })
		pageFeatures.sidebar:createInfo({ text = creditsText })

		-- Category: Tooltips
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.tooltips") })

			-- Help tooltips
			category:createOnOffButton({
				label = common.i18n("mcm.showHelpTips.label"),
				description = common.i18n("mcm.showHelpTips.description"),
				variable = mwse.mcm.createTableVariable({ id = "showHelpText", table = common.config }),
			})

			-- Display value/weight ratio
			category:createOnOffButton({
				label = common.i18n("mcm.ratioDisplay.label"),
				description = common.i18n("mcm.ratioDisplay.description"),
				variable = mwse.mcm.createTableVariable({ id = "displayRatio", table = common.config }),
			})

			-- Center-align icon bar
			category:createOnOffButton({
				label = common.i18n("mcm.iconBarCenterAlign.label"),
				description = common.i18n("mcm.iconBarCenterAlign.description"),
				variable = mwse.mcm.createTableVariable({ id = "iconBarCenterAlign", table = common.config })
			})

			-- Icon bar location
			category:createDropdown({
				label = common.i18n("mcm.iconBarLocation.label"),
				description = common.i18n("mcm.iconBarLocation.description"),
				options = {
					{ label = common.i18n("mcm.iconBarLocationOptions.1"), value = "Top" },
					{ label = common.i18n("mcm.iconBarLocationOptions.2"), value = "Below item name" },
					{ label = common.i18n("mcm.iconBarLocationOptions.3"), value = "Above enchantments" },
					{ label = common.i18n("mcm.iconBarLocationOptions.4"), value = "Above flavor text" },
					{ label = common.i18n("mcm.iconBarLocationOptions.5"), value = "Bottom" },
				},
				variable = mwse.mcm.createTableVariable({ id = "iconBarLocation", table = common.config }),
			})
		end

		-- Category: Search & Filtering
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.searchFilter") })

			-- Use text search?
			category:createOnOffButton({
				label = common.i18n("mcm.useSearchBars.label"),
				description = common.i18n("mcm.useSearchBars.description"),
				variable = mwse.mcm.createTableVariable({ id = "useSearch", table = common.config }),
			})

			-- Use effect text search?
			category:createOnOffButton({
				label = common.i18n("mcm.useSearchBars.searchEffects.label"),
				description = common.i18n("mcm.useSearchBars.searchEffects.description"),
				variable = mwse.mcm.createTableVariable({ id = "useSearchEffects", table = common.config }),
			})

			-- Use slot/type text search?
			category:createOnOffButton({
				label = common.i18n("mcm.useSearchBars.searchTypes.label"),
				description = common.i18n("mcm.useSearchBars.searchTypes.description"),
				variable = mwse.mcm.createTableVariable({ id = "useSearchTypes", table = common.config }),
			})

			-- Use soul text search?
			category:createOnOffButton({
				label = common.i18n("mcm.useSearchBars.searchSouls.label"),
				description = common.i18n("mcm.useSearchBars.searchSouls.description"),
				variable = mwse.mcm.createTableVariable({ id = "useSearchSouls", table = common.config }),
			})

			-- Use buttons or icons?
			category:createOnOffButton({
				label = common.i18n("mcm.filterButtons.label"),
				description = common.i18n("mcm.filterButtons.description"),
				variable = mwse.mcm.createTableVariable({ id = "useInventoryTextButtons", table = common.config }),
			})

			-- Auto-selection
			category:createDropdown({
				label = common.i18n("mcm.autoSelectSearch.label"),
				description = common.i18n("mcm.autoSelectSearch.description"),
				options = {
					{ label = common.i18n("mcm.autoSelectSearch.option.inventory"), value = "Inventory" },
					{ label = common.i18n("mcm.autoSelectSearch.option.magic"), value = "Magic" },
					{ label = common.i18n("mcm.autoSelectSearch.option.none"), value = "None" },
				},
				variable = mwse.mcm.createTableVariable({ id = "autoSelectInput", table = common.config }),
			})

			-- Auto-equip spells
			category:createOnOffButton({
				label = common.i18n("mcm.autoSelectSpells.label"),
				description = common.i18n("mcm.autoSelectSpells.description"),
				variable = mwse.mcm.createTableVariable({ id = "selectSpellsOnSearch", table = common.config }),
			})

			-- Auto-filter to barterable items
			category:createOnOffButton({
				label = common.i18n("mcm.autoFilterToTradable.label"),
				description = common.i18n("mcm.autoFilterToTradable.description"),
				variable = mwse.mcm.createTableVariable({ id = "autoFilterToTradable", table = common.config }),
			})

			-- Auto-clear filters
			category:createOnOffButton({
				label = common.i18n("mcm.alwaysClearFiltersOnOpen.label"),
				description = common.i18n("mcm.alwaysClearFiltersOnOpen.description"),
				variable = mwse.mcm.createTableVariable({ id = "alwaysClearFiltersOnOpen", table = common.config }),
			})

			-- Quick-transfer items without having to hold alt
			category:createOnOffButton({
				label = common.i18n("mcm.transferStackByDefault.label"),
				description = common.i18n("mcm.transferStackByDefault.description"),
				variable = mwse.mcm.createTableVariable({ id = "transferItemsByDefault", table = common.config }),
			})
		end

		-- Category: Console
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.console") })

			-- Help tooltips
			category:createTextField({
				label = common.i18n("mcm.consoleHistoryLimit.label"),
				description = common.i18n("mcm.consoleHistoryLimit.description"),
				variable = mwse.mcm.createTableVariable({ id = "consoleHistoryLimit", converter = tonumber, table = common.config }),
				numbersOnly = true,
			})
		end

		-- Category: Dialogue
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.dialogue") })

			-- Display player dialogue choices.
			category:createOnOffButton({
				label = common.i18n("mcm.displayPlayerDialogueChoices.label"),
				description = common.i18n("mcm.displayPlayerDialogueChoices.description"),
				variable = mwse.mcm.createTableVariable({ id = "displayPlayerDialogueChoices", table = common.config }),
			})
		end

		-- Category: Map Menu
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.map") })

			-- Change map mode on cell change
			category:createOnOffButton({
				label = common.i18n("mcm.changeMapModeOnCellChange.label"),
				description = common.i18n("mcm.changeMapModeOnCellChange.description"),
				variable = mwse.mcm.createTableVariable({ id = "changeMapModeOnCellChange", table = common.config }),
			})
		end

		-- Category: Map extension plugin
		if externMapPlugin then
			local category = pageFeatures:createCategory({
				label = common.i18n("mcm.category.mapExtension"),
				postCreate = function(self)
					local mapData = externMapPlugin.getMapData()

					local c = self.components[1]
					c.elements.info.text = common.i18n("mcm.mapExtension.mapBounds.label", { mapData.minX, mapData.minY, mapData.maxX, mapData.maxY })
					c = self.components[2]
					c.elements.info.text = common.i18n("mcm.mapExtension.textureSize.label", { mapData.mapWidth, mapData.mapHeight })
				end
			})

			category:createActiveInfo({
				text = "",
				description = common.i18n("mcm.mapExtension.mapBounds.description"),
			})
			category:createActiveInfo({
				text = "",
				description = common.i18n("mcm.mapExtension.textureSize.description"),
			})

			category:createOnOffButton({
				label = common.i18n("mcm.mapExtension.autoMapBounds.label"),
				description = common.i18n("mcm.mapExtension.autoMapBounds.description"),
				variable = mwse.mcm.createTableVariable({ id = "autoMapBounds", table = common.config.mapConfig }),
				restartRequired = true,
			})
			category:createSlider({
				label = common.i18n("mcm.mapExtension.minX.label"),
				variable = mwse.mcm.createTableVariable({ id = "minX", table = common.config.mapConfig }),
				min = -300,
				max = -28, 
			})
			category:createSlider({
				label = common.i18n("mcm.mapExtension.maxX.label"),
				variable = mwse.mcm.createTableVariable({ id = "maxX", table = common.config.mapConfig }),
				min = 28,
				max = 300, 
			})
			category:createSlider({
				label = common.i18n("mcm.mapExtension.minY.label"),
				variable = mwse.mcm.createTableVariable({ id = "minY", table = common.config.mapConfig }),
				min = -300,
				max = -28, 
			})
			category:createSlider({
				label = common.i18n("mcm.mapExtension.maxY.label"),
				variable = mwse.mcm.createTableVariable({ id = "maxY", table = common.config.mapConfig }),
				min = 28,
				max = 300, 
			})
			category:createButton({
				buttonText = ". . .",
				label = common.i18n("mcm.mapExtension.redrawRegion.label"),
				description = common.i18n("mcm.mapExtension.redrawRegion.description"),
				inGameOnly = true,
				callback = function() common.createMapRedrawMenu() end,
			})
		end

		-- Category: Rest & Wait Menu
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.restWait") })

			-- Display day of week in rest menu
			category:createOnOffButton({
				label = common.i18n("mcm.showWeekDay.label"),
				description = common.i18n("mcm.showWeekDay.description"),
				variable = mwse.mcm.createTableVariable({ id = "displayWeekday", table = common.config }),
			})

			-- Display target rest hour
			category:createOnOffButton({
				label = common.i18n("mcm.displayRestTargetHour.label"),
				description = common.i18n("mcm.displayRestTargetHour.description"),
				variable = mwse.mcm.createTableVariable({ id = "displayRestTargetHour", table = common.config }),
			})

			-- Max number of days to wait/rest
			category:createTextField({
				label = common.i18n("mcm.maxWaitDays.label"),
				description = common.i18n("mcm.maxWaitDays.description"),
				variable = mwse.mcm.createTableVariable({ id = "maxWait", converter = tonumber, table = common.config }),
				numbersOnly = true,
			})
		end

		-- Category: Key Configuration
		do
			local category = pageFeatures:createCategory({ label = common.i18n("mcm.category.keyConfig") })

			-- Key binding: take all/filtered
			category:createKeyBinder({
				label = common.i18n("mcm.takeAllKey.label"),
				description = common.i18n("mcm.takeAllKey.description"),
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindTakeAll", table = common.config }),
			})

			-- Key binding: map switch
			category:createKeyBinder({
				label = common.i18n("mcm.mapSwitchKey.label"),
				description = common.i18n("mcm.mapSwitchKey.description"),
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindMapSwitch", table = common.config }),
			})

			-- Key binding: show additional info
			category:createKeyBinder({
				label = common.i18n("mcm.showAdditionalInfoKey.label"),
				description = common.i18n("mcm.showAdditionalInfoKey.description"),
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindShowAdditionalInfo", table = common.config }),
			})
		end
	end

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
