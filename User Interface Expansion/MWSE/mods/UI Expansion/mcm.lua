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

	local button = horizontalBlock:createButton({ text = (this.config[params.key] and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value) })
	button.absolutePosAlignX = 1.0
	button.absolutePosAlignY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		this.config[params.key] = not this.config[params.key]
		button.text = this.config[params.key] and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value

		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	return { block = horizontalBlock, label = label, button = button }
end

local function changeToNextAutoSelectInput(e)
	local text = e.source.text

	if (text == "Inventory") then
		text = "Magic"
	elseif (text == "Magic") then
		text = "None"
	else
		text = "Inventory"
	end

	e.source.text = text
	this.config.autoSelectInput = text
end

function this.onCreate(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0
	mainPane.paddingAllSides = 6

	--
	local title = mainPane:createLabel({ text = "UI Expansion v1.0" })
	title.borderBottom = 6

	-- Allow selecting the default focus for searching.
	do
		-- The container is a scroll list. Create a row in that list that organizes elements horizontally.
		local horizontalBlock = mainPane:createBlock({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.widthProportional = 1.0
		horizontalBlock.height = 32

		-- The text for the config option.
		local label = horizontalBlock:createLabel({ text = "Auto-select search bar:" })
		label.absolutePosAlignX = 0.0
		label.absolutePosAlignY = 0.5

		-- Button that toggles the config value.
		local button = horizontalBlock:createButton({ text = this.config.autoSelectInput })
		button.absolutePosAlignX = 1.0
		button.absolutePosAlignY = 0.5
		button:register("mouseClick", changeToNextAutoSelectInput)
	end

	-- Toggle help text.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Show help tooltips where available?",
		config = this.config,
		key = "showHelpText",
	})

	-- Toggle vanilla-style inventory filter buttons.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Use verbose buttons instead of icons for inventory filtering?",
		config = this.config,
		key = "useInventoryTextButtons",
		onUpdate = function(e)
			common.inventoryFilter:setIconUsage(not this.config.useInventoryTextButtons)
			common.barterFilter:setIconUsage(not this.config.useInventoryTextButtons)
		end
	})

	-- Toggle search bars.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Use search bars?",
		config = this.config,
		key = "useSearch",
		onUpdate = function(e)
			common.inventoryFilter:setSearchBarUsage(this.config.useSearch)
			common.inventoryFilter:clearFilter()
			common.magicFilter:setSearchBarUsage(this.config.useSearch)
			common.magicFilter:clearFilter()
			common.barterFilter:setSearchBarUsage(this.config.useSearch)
			common.barterFilter:clearFilter()
		end
	})

	-- Toggle help text.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Auto-select first result when searching spell list?",
		config = this.config,
		key = "selectSpellsOnSearch",
	})

	-- Toggle auto-filtering to tradable items when bartering.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Filter to tradable items when opening barter window?",
		config = this.config,
		key = "autoFilterToTradable",
	}) 
 
	-- Take only filtered items in contents menu.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Replace Take All with Take Filtered in contents menu?",
		config = this.config,
		key = "takeFilteredItems",
	})
 
	-- Toggle displaying the weekday in the rest menu.
	createBooleanConfigPackage({
		parent = mainPane,
		label = "Display weekday in rest menu?",
		config = this.config,
		key = "displayWeekday",
	})

	-- Credits:
	mainPane:createLabel({ text = "Credits:" }).borderTop = 6
	mainPane:createLabel({ text = "  Programming: NullCascade, Hrnchamd" })
	mainPane:createLabel({ text = "  Additional Programming: Petethegoat, Jiopsi" })
	mainPane:createLabel({ text = "  Colored Magic School Icons: R-Zero" })
	mainPane:createLabel({ text = "  Inventory Filter Icons: Remiros" })
	mainPane:createLabel({ text = "  Concepts and Testing: Morrowind Modding Community Discord" })
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function this.onClose(container)
	mwse.saveConfig("UI Expansion", this.config)
end

return this