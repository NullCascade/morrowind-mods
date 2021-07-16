
local common = require("UI Expansion.common")

local function saveConfig()
	mwse.saveConfig("UI Expansion", common.config)
end

-- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "UI Expansion" })
	template:saveOnClose("UI Expansion", common.config)

	local creditsText = common.dictionary.modName .. " " .. common.dictionary.versionString
		.. "\n\n" .. common.dictionary.configCredits
		.. "\n  Programming: NullCascade, Hrnchamd, Petethegoat, Jiopsi, Remiros, Mort, Wix, abot, Necrolesian"
		.. "\n  Colored Magic School Icons: R-Zero"
		.. "\n  Inventory Filter Icons: Remiros"
		.. "\n  Training Skill Icons: RedFurryDemon"
		.. "\n  Value/Weight Ratio Icon: Necrolesian"
		.. "\n  Concepts and Testing: Morrowind Modding Community Discord"
	
	-- Components section
	do
		local pageComponents = template:createSideBarPage({ label = common.dictionary.configTabComponent })
		pageComponents.sidebar:createInfo({ text = creditsText .. "\n\nThe settings in this tab will not take affect until the next restart." })

		local components = {
			barter = "configComponentBarter",
			console = "configComponentConsole",
			contents = "configComponentContents",
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
			serviceTraining = "configComponentServiceTraining",
		}
		for _, k in ipairs(table.keys(components)) do
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

		-- Help tooltips
		pageFeatures:createOnOffButton({
			label = common.dictionary.configShowHelpTips,
			description = common.dictionary.configShowHelpTipsDescription,
			variable = mwse.mcm.createTableVariable({ id = "showHelpText", table = common.config }),
		})

		-- Use text search?
		pageFeatures:createOnOffButton({
			label = common.dictionary.configUseSearchBars,
			description = common.dictionary.configUseSearchBarsDescription,
			variable = mwse.mcm.createTableVariable({ id = "useSearch", table = common.config }),
		})

		-- Use text search?
		pageFeatures:createOnOffButton({
			label = common.dictionary.configFilterButtons,
			description = common.dictionary.configFilterButtonsDescription,
			variable = mwse.mcm.createTableVariable({ id = "useInventoryTextButtons", table = common.config }),
		})

		-- Auto-selection
		pageFeatures:createDropdown({
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
		pageFeatures:createOnOffButton({
			label = common.dictionary.configAutoSelectSpells,
			description = common.dictionary.configAutoSelectSpellsDescription,
			variable = mwse.mcm.createTableVariable({ id = "selectSpellsOnSearch", table = common.config }),
		})

		-- Auto-filter to barterable items
		pageFeatures:createOnOffButton({
			label = common.dictionary.configAutoFilterToTradable,
			description = common.dictionary.configAutoFilterToTradableDescription,
			variable = mwse.mcm.createTableVariable({ id = "autoFilterToTradable", table = common.config }),
		})

		-- Auto-clear filters
		pageFeatures:createOnOffButton({
			label = common.dictionary.configAlwaysClearFiltersOnOpen,
			description = common.dictionary.configAlwaysClearFiltersOnOpenDescription,
			variable = mwse.mcm.createTableVariable({ id = "alwaysClearFiltersOnOpen", table = common.config }),
		})

		-- Display value/weight ratio
		pageFeatures:createOnOffButton({
			label = common.dictionary.configRatioDisplay,
			description = common.dictionary.configRatioDisplayDescription,
			variable = mwse.mcm.createTableVariable({ id = "displayRatio", table = common.config }),
		})

		-- Quick-transfer items without having to hold alt
		pageFeatures:createOnOffButton({
			label = common.dictionary.configTransferStackByDefault,
			description = common.dictionary.configTransferStackByDefaultDescription,
			variable = mwse.mcm.createTableVariable({ id = "transferItemsByDefault", table = common.config }),
		})

		-- Display day of week in rest menu
		pageFeatures:createOnOffButton({
			label = common.dictionary.configShowWeekDay,
			description = common.dictionary.configShowWeekDayDescription,
			variable = mwse.mcm.createTableVariable({ id = "displayWeekday", table = common.config }),
		})

		-- Display target rest hour
		pageFeatures:createOnOffButton({
			label = common.dictionary.configDisplayRestTargetHour,
			description = common.dictionary.configDisplayRestTargetHourDescription,
			variable = mwse.mcm.createTableVariable({ id = "displayRestTargetHour", table = common.config }),
		})

		-- Max number of days to wait/rest
		pageFeatures:createTextField({
			label = common.dictionary.configMaxWaitDays,
			description = common.dictionary.configMaxWaitDaysDescription,
			variable = mwse.mcm.createTableVariable({ id = "maxWait", converter = tonumber, table = common.config }),
			numbersOnly = true
		})

		-- Key binding: close inventory
		pageFeatures:createKeyBinder({
			label = common.dictionary.configCloseKey,
			description = common.dictionary.configCloseKeyDescription,
			allowCombinations = true,
			variable = mwse.mcm.createTableVariable({ id = "keybindClose", table = common.config }),
		})

		-- Key binding: take all/filtered
		pageFeatures:createKeyBinder({
			label = common.dictionary.configTakeAllKey,
			description = common.dictionary.configTakeAllKeyDescription,
			allowCombinations = true,
			variable = mwse.mcm.createTableVariable({ id = "keybindTakeAll", table = common.config }),
		})

		-- Key binding: show additional info
		pageFeatures:createKeyBinder({
			label = common.dictionary.configShowAdditionalInfoKey,
			description = common.dictionary.configShowAdditionalInfoKeyDescription,
			allowCombinations = true,
			variable = mwse.mcm.createTableVariable({ id = "keybindShowAdditionalInfo", table = common.config }),
		})

		-- Display target rest hour
		pageFeatures:createOnOffButton({
			label = common.dictionary.configChangeMapModeOnCellChange,
			description = common.dictionary.configChangeMapModeOnCellChangeDescription,
			variable = mwse.mcm.createTableVariable({ id = "changeMapModeOnCellChange", table = common.config }),
		})

		-- Key binding: map switch
		pageFeatures:createKeyBinder({
			label = common.dictionary.configMapSwitchKey,
			description = common.dictionary.configMapSwitchKeyDescription,
			allowCombinations = true,
			variable = mwse.mcm.createTableVariable({ id = "keybindMapSwitch", table = common.config }),
		})
	end
	
	-- Finish up.
	template:register()
end
event.register("modConfigReady", registerModConfig)
