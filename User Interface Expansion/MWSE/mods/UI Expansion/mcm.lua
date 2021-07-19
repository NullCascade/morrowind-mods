local common = require("UI Expansion.common")

local function saveConfig()
	mwse.saveConfig("UI Expansion", common.config)
end

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "UI Expansion" })
	template:saveOnClose("UI Expansion", common.config)

	local creditsText = common.dictionary.modName .. " " .. common.dictionary.versionString .. "\n\n" ..
	                    common.dictionary.configCredits ..
	                    "\n  Programming: NullCascade, Hrnchamd, Petethegoat, Jiopsi, Remiros, Mort, Wix, abot, Necrolesian" ..
	                    "\n  Translations: Daichix, Fesswood, Monsterzeichner, and Google Translate" ..
	                    "\n  Concepts and Testing: Morrowind Modding Community Discord" ..
	                    "\n  Colored Magic School Icons: R-Zero" .. "\n  Inventory Filter Icons: Remiros" ..
	                    "\n  Training Skill Icons: RedFurryDemon" .. "\n  Value/Weight Ratio Icon: Necrolesian"

	-- Components section
	do
		local pageComponents = template:createSideBarPage({ label = common.dictionary.configTabComponent })
		pageComponents.sidebar:createInfo({
			text = creditsText .. "\n\nThe settings in this tab will not take affect until the next restart.",
		})

		local components = {
			barter = "configComponentBarter",
			console = "configComponentConsole",
			contents = "configComponentContents",
			copyPaste = "configComponentCopyPaste",
			dialog = "configComponentDialog",
			inventory = "configComponentInventory",
			inventorySelect = "configComponentInventorySelect",
			magic = "configComponentMagic",
			map = "configComponentMap",
			options = "configComponentOptions",
			quantity = "configComponentQuantity",
			rest = "configComponentRest",
			saveLoad = "configComponentSaveLoad",
			serviceSpells = "configComponentServiceSpells",
			training = "configComponentServiceTraining",
		}
		for _, k in ipairs(table.keys(components, true)) do
			pageComponents:createOnOffButton({
				label = common.dictionary[components[k]],
				description = common.dictionary[components[k] .. "Description"],
				variable = mwse.mcm.createTableVariable({ id = k, table = common.config.components }),
			})
		end
	end

	-- Features setting
	do
		local pageFeatures = template:createSideBarPage({ label = common.dictionary.configTabFeature })
		pageFeatures.sidebar:createInfo({ text = creditsText })

		-- Category: Tooltips
		do
			local category = pageFeatures:createCategory({ label = common.dictionary.configCategoryTooltips })

			-- Help tooltips
			category:createOnOffButton({
				label = common.dictionary.configShowHelpTips,
				description = common.dictionary.configShowHelpTipsDescription,
				variable = mwse.mcm.createTableVariable({ id = "showHelpText", table = common.config }),
			})

			-- Display value/weight ratio
			category:createOnOffButton({
				label = common.dictionary.configRatioDisplay,
				description = common.dictionary.configRatioDisplayDescription,
				variable = mwse.mcm.createTableVariable({ id = "displayRatio", table = common.config }),
			})
		end

		-- Category: Search & Filtering
		do
			local category = pageFeatures:createCategory({ label = common.dictionary.configCategorySearchFilter })

			-- Use text search?
			category:createOnOffButton({
				label = common.dictionary.configUseSearchBars,
				description = common.dictionary.configUseSearchBarsDescription,
				variable = mwse.mcm.createTableVariable({ id = "useSearch", table = common.config }),
			})

			-- Use buttons or icons?
			category:createOnOffButton({
				label = common.dictionary.configFilterButtons,
				description = common.dictionary.configFilterButtonsDescription,
				variable = mwse.mcm.createTableVariable({ id = "useInventoryTextButtons", table = common.config }),
			})

			-- Auto-selection
			category:createDropdown({
				label = common.dictionary.configAutoSelectSearch,
				description = common.dictionary.configAutoSelectSearchDescription,
				options = {
					{ label = common.dictionary.configAutoSelectSearchOptions[1], value = "Inventory" },
					{ label = common.dictionary.configAutoSelectSearchOptions[2], value = "Magic" },
					{ label = common.dictionary.configAutoSelectSearchOptions[3], value = "None" },
				},
				variable = mwse.mcm.createTableVariable({ id = "autoSelectInput", table = common.config }),
			})

			-- Auto-equip spells
			category:createOnOffButton({
				label = common.dictionary.configAutoSelectSpells,
				description = common.dictionary.configAutoSelectSpellsDescription,
				variable = mwse.mcm.createTableVariable({ id = "selectSpellsOnSearch", table = common.config }),
			})

			-- Auto-filter to barterable items
			category:createOnOffButton({
				label = common.dictionary.configAutoFilterToTradable,
				description = common.dictionary.configAutoFilterToTradableDescription,
				variable = mwse.mcm.createTableVariable({ id = "autoFilterToTradable", table = common.config }),
			})

			-- Auto-clear filters
			category:createOnOffButton({
				label = common.dictionary.configAlwaysClearFiltersOnOpen,
				description = common.dictionary.configAlwaysClearFiltersOnOpenDescription,
				variable = mwse.mcm.createTableVariable({ id = "alwaysClearFiltersOnOpen", table = common.config }),
			})

			-- Quick-transfer items without having to hold alt
			category:createOnOffButton({
				label = common.dictionary.configTransferStackByDefault,
				description = common.dictionary.configTransferStackByDefaultDescription,
				variable = mwse.mcm.createTableVariable({ id = "transferItemsByDefault", table = common.config }),
			})
		end

		-- Category: Console
		do
			local category = pageFeatures:createCategory({ label = common.dictionary.configCategoryConsole })

			-- Help tooltips
			category:createTextField({
				label = common.dictionary.configConsoleHistoryLimit,
				description = common.dictionary.configConsoleHistoryLimitDescription,
				variable = mwse.mcm.createTableVariable({ id = "consoleHistoryLimit", converter = tonumber, table = common.config }),
				numbersOnly = true,
			})
		end

		-- Category: Map Menu
		do
			local category = pageFeatures:createCategory({ label = common.dictionary.configCategoryMap })

			-- Change map mode on cell change
			category:createOnOffButton({
				label = common.dictionary.configChangeMapModeOnCellChange,
				description = common.dictionary.configChangeMapModeOnCellChangeDescription,
				variable = mwse.mcm.createTableVariable({ id = "changeMapModeOnCellChange", table = common.config }),
			})
		end

		-- Category: Rest & Wait Menu
		do
			local category = pageFeatures:createCategory({ label = common.dictionary.configCategoryRestWait })

			-- Display day of week in rest menu
			category:createOnOffButton({
				label = common.dictionary.configShowWeekDay,
				description = common.dictionary.configShowWeekDayDescription,
				variable = mwse.mcm.createTableVariable({ id = "displayWeekday", table = common.config }),
			})

			-- Display target rest hour
			category:createOnOffButton({
				label = common.dictionary.configDisplayRestTargetHour,
				description = common.dictionary.configDisplayRestTargetHourDescription,
				variable = mwse.mcm.createTableVariable({ id = "displayRestTargetHour", table = common.config }),
			})

			-- Max number of days to wait/rest
			category:createTextField({
				label = common.dictionary.configMaxWaitDays,
				description = common.dictionary.configMaxWaitDaysDescription,
				variable = mwse.mcm.createTableVariable({ id = "maxWait", converter = tonumber, table = common.config }),
				numbersOnly = true,
			})
		end

		-- Category: Key Configuration
		do
			local category = pageFeatures:createCategory({ label = common.dictionary.configCategoryKeyConfig })

			-- Key binding: close inventory
			category:createKeyBinder({
				label = common.dictionary.configCloseKey,
				description = common.dictionary.configCloseKeyDescription,
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindClose", table = common.config }),
			})

			-- Key binding: take all/filtered
			category:createKeyBinder({
				label = common.dictionary.configTakeAllKey,
				description = common.dictionary.configTakeAllKeyDescription,
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindTakeAll", table = common.config }),
			})

			-- Key binding: map switch
			category:createKeyBinder({
				label = common.dictionary.configMapSwitchKey,
				description = common.dictionary.configMapSwitchKeyDescription,
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindMapSwitch", table = common.config }),
			})

			-- Key binding: show additional info
			category:createKeyBinder({
				label = common.dictionary.configShowAdditionalInfoKey,
				description = common.dictionary.configShowAdditionalInfoKeyDescription,
				allowCombinations = true,
				variable = mwse.mcm.createTableVariable({ id = "keybindShowAdditionalInfo", table = common.config }),
			})
		end
	end

	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
