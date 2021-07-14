local this = {}

local function createConfigSliderPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.layoutWidthFraction = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.layoutOriginFractionX = 0.0
	label.layoutOriginFractionY = 0.5

	local config = params.config
	local key = params.key
	local value = config[key] or params.default or 0
	
	local sliderLabel = horizontalBlock:createLabel({ text = tostring(value) })
	sliderLabel.layoutOriginFractionX = 1.0
	sliderLabel.layoutOriginFractionY = 0.5
	sliderLabel.borderRight = 306

	local range = params.max - params.min

	local slider = horizontalBlock:createSlider({ current = value - params.min, max = range, step = params.step, jump = params.jump })
	slider.layoutOriginFractionX = 1.0
	slider.layoutOriginFractionY = 0.5
	slider.width = 300
	slider:register("PartScrollBar_changed", function(e)
		config[key] = slider:getPropertyInt("PartScrollBar_current") + params.min
		sliderLabel.text = config[key]
		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	if (params.tooltip) then
		local tooltipType = type(params.tooltip)
		if (tooltipType == "string") then
			slider:register("help", function(e)
				local tooltipMenu = tes3ui.createTooltipMenu()
				local tooltipText = tooltipMenu:createLabel({ text = params.tooltip })
				tooltipText.wrapText = true
			end)
		elseif (tooltipType == "function") then
			slider:register("help", params.tooltip)
		end
	end

	return { block = horizontalBlock, label = label, sliderLabel = sliderLabel, slider = slider }
end

local function createBooleanConfigPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.layoutWidthFraction = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.layoutOriginFractionX = 0.0
	label.layoutOriginFractionY = 0.5

	local button = horizontalBlock:createButton({ text = (this.config[params.key] and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value) })
	button.layoutOriginFractionX = 1.0
	button.layoutOriginFractionY = 0.5
	button.paddingTop = 3
	button:register("mouseClick", function(e)
		this.config[params.key] = not this.config[params.key]
		button.text = this.config[params.key] and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
		
		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	if (params.tooltip) then
		local tooltipType = type(params.tooltip)
		if (tooltipType == "string") then
			button:register("help", function(e)
				local tooltipMenu = tes3ui.createTooltipMenu()
				local tooltipText = tooltipMenu:createLabel({ text = params.tooltip })
				tooltipText.wrapText = true
			end)
		elseif (tooltipType == "function") then
			button:register("help", params.tooltip)
		end
	end

	return { block = horizontalBlock, label = label, button = button }
end

function this.onCreate(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	
	local configImage = mainPane:createImage { path = "textures/GITD_Header.dds" }
	configImage.absolutePosAlignX = 0.5

	createConfigSliderPackage({
		parent = mainPane,
		label = "Dawn hour:",
		config = this.config,
		key = "dawnHour",
		min = 4,
		max = 8,
		step = 1,
		jump = 1,
		tooltip = "Hour when objects transition to daytime appearance.\n\nDefault: 6",
	})

	createConfigSliderPackage({
		parent = mainPane,
		label = "Dusk hour:",
		config = this.config,
		key = "duskHour",
		min = 18,
		max = 22,
		step = 1,
		jump = 1,
		tooltip = "Hour when objects transition to nighttime appearance.\n\nDefault: 20",
	})

	createBooleanConfigPackage({
		parent = mainPane,
		label = "Stagger exterior transitions:",
		config = this.config,
		key = "useVariance",
		tooltip = "Objects will light up and go dark at different times.\n\nDefault: Yes",
	})

	createConfigSliderPackage({
		parent = mainPane,
		label = "Maximum stagger (in minutes):",
		config = this.config,
		key = "varianceInMinutes",
		min = 1,
		max = 240,
		step = 5,
		jump = 15,
		tooltip = "Sets the amount of time objects will randomly transition around the dusk or dawn hour.\n\nDefault: 30",
	})
end

function this.onClose(container)
	mwse.saveConfig("Glow in the Dahrk", this.config)
end

return this