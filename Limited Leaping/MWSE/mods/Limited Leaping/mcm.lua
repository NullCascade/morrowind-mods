local this = {}

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

function this.onCreate(container)
	-- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0
	mainPane.paddingAllSides = 6

	--
	local title = mainPane:createLabel({ text = "Limited Leaping v1.0" })
	title.borderBottom = 6

	-- Slider for cooldown.
	createConfigSliderPackage({
		parent = mainPane,
		label = "Cooldown between jumps (0 to disable):",
		config = this.config,
		key = "cooldown",
		min = 0,
		max = 10,
		jump = 1,
		step = 1,
	})

	-- Slider for minimum fatigue.
	createConfigSliderPackage({
		parent = mainPane,
		label = "Minimum fatigue to jump (0 to disable):",
		config = this.config,
		key = "minimumFatigue",
		min = 0,
		max = 100,
		jump = 10,
		step = 1,
	})
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function this.onClose(_)
	mwse.saveConfig("Limited Leaping", this.config)
end

return this