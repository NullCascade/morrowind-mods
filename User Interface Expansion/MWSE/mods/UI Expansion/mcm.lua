local this = {}

local common = require("UI Expansion.common")

local function createConfigSliderPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.widthProportional = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.absolutePosAlignX = 0.0
	label.absolutePosAlignY = 0.5

	local config = params.config
	local key = params.key
	local value = config[key] or params.default or 0

	local sliderLabel = horizontalBlock:createLabel({ text = tostring(value) })
	sliderLabel.absolutePosAlignX = 1.0
	sliderLabel.absolutePosAlignY = 0.5
	sliderLabel.borderRight = 306

	local range = params.max - params.min

	local slider = horizontalBlock:createSlider({ current = value - params.min, max = range, step = params.step, jump = params.jump })
	slider.absolutePosAlignX = 1.0
	slider.absolutePosAlignY = 0.5
	slider.width = 300
	slider:register("PartScrollBar_changed", function(e)
		config[key] = slider:getPropertyInt("PartScrollBar_current") + params.min
		sliderLabel.text = config[key]
		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	return { block = horizontalBlock, label = label, sliderLabel = sliderLabel, slider = slider }
end

local function createBooleanConfigPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.widthProportional = 1.0
	horizontalBlock.height = 32

	local label = horizontalBlock:createLabel({ text = params.label })
	label.absolutePosAlignX = 0.0
	label.absolutePosAlignY = 0.5

	local button = horizontalBlock:createButton({ text = (this.config[params.key] and common.dictionary.yes or common.dictionary.no) })
	button.absolutePosAlignX = 1.0
	button.absolutePosAlignY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		this.config[params.key] = not this.config[params.key]
		button.text = this.config[params.key] and common.dictionary.yes or common.dictionary.no

		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	return { block = horizontalBlock, label = label, button = button }
end

local function createTableConfigPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.widthProportional = 1.0
	horizontalBlock.height = 32

	local label = horizontalBlock:createLabel({ text = params.label })
	label.absolutePosAlignX = 0.0
	label.absolutePosAlignY = 0.5

	local button = horizontalBlock:createButton({ text = this.config[params.key] })
	button.absolutePosAlignX = 1.0
	button.absolutePosAlignY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		for k,v in pairs(params.table) do
			if (v == this.config[params.key]) then
				this.config[params.key] = params.table[k + 1] or params.table[1]
				button.text = params.names[k + 1] or params.names[1]
				break
			end
		end

		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	return { block = horizontalBlock, label = label, button = button }
end

function this.onCreate(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0
	mainPane.paddingAllSides = 6

	--
	local title = mainPane:createLabel({ text = string.format("%s %s", common.dictionary.modName, common.dictionary.versionString) })
	title.borderBottom = 6

	-- Allow selecting the default focus for searching.
	createTableConfigPackage({
		parent = mainPane,
		label = common.dictionary.configAutoSelectSearch,
		config = this.config,
		key = "autoSelectInput",
		table = { "Inventory", "Magic", "None" },
		names = common.dictionary.configAutoSelectSearchOptions
	})

	-- Toggle help text.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configShowHelpTips,
		config = this.config,
		key = "showHelpText",
	})

	-- Toggle vanilla-style inventory filter buttons.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configFilterButtons,
		config = this.config,
		key = "useInventoryTextButtons",
		onUpdate = function()
			common.inventoryFilter:setIconUsage(not this.config.useInventoryTextButtons)
			common.barterFilter:setIconUsage(not this.config.useInventoryTextButtons)
		end
	})

	-- Toggle search bars.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configUseSearchBars,
		config = this.config,
		key = "useSearch",
		onUpdate = function()
			common.setAllFiltersVisibility(this.config.useSearch)
		end
	})

	-- Toggle help text.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configAutoSelectSpells,
		config = this.config,
		key = "selectSpellsOnSearch",
	})

	-- Toggle auto-filtering to tradable items when bartering.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configAutoFilterToTradable,
		config = this.config,
		key = "autoFilterToTradable",
	})

	-- Take only filtered items in contents menu.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configUseTakeFiltered,
		config = this.config,
		key = "takeFilteredItems",
	})

	-- Transfer items with single click by default.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configTransferStackByDefault,
		config = this.config,
		key = "transferItemsByDefault",
	})

	-- Toggle displaying the weekday in the rest menu.
	createBooleanConfigPackage({
		parent = mainPane,
		label = common.dictionary.configShowWeekDay,
		config = this.config,
		key = "displayWeekday",
	})

	-- Select the maximum wait time.
	createConfigSliderPackage({
		parent = mainPane,
		label = common.dictionary.configMaxWaitDays,
		config = this.config,
		key = "maxWait",
		min = 1,
		max = 14,
		jump = 7,
		step = 1,
	})

	-- Credits:
	mainPane:createLabel({ text = common.dictionary.configCredits }).borderTop = 6
	mainPane:createLabel({ text = "  Programming: NullCascade, Hrnchamd, Petethegoat, Jiopsi, Remiros, Mort, Wix, abot" })
	mainPane:createLabel({ text = "  Colored Magic School Icons: R-Zero" })
	mainPane:createLabel({ text = "  Inventory Filter Icons: Remiros" })
	mainPane:createLabel({ text = "  Training Skill Icons: RedFurryDemon" })
	mainPane:createLabel({ text = "  Concepts and Testing: Morrowind Modding Community Discord" })
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function this.onClose()
	mwse.saveConfig("UI Expansion", this.config)
end

return this