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

    local button = horizontalBlock:createButton({ text = (this.config[params.key] and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value) })
    button.layoutOriginFractionX = 1.0
    button.layoutOriginFractionY = 0.5
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

function this.onCreate(container)
    -- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0
    mainPane.paddingAllSides = 6

    -- 
    mainPane:createLabel({ text = "UI Expansion v1.0" }).borderBottom = 6

    -- 
    createBooleanConfigPackage({
        parent = mainPane,
        label = "Show help tooltips where available?",
        config = this.config,
        key = "showHelpText",
    })
    
    -- Credits:
    mainPane:createLabel({ text = "Credits:" }).borderTop = 6
    mainPane:createLabel({ text = "  Programming: NullCascade" })
    mainPane:createLabel({ text = "  Colored School Icons: R-Zero" })
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function this.onClose(container)
	mwse.saveConfig("UI Expansion", this.config)
end

return this