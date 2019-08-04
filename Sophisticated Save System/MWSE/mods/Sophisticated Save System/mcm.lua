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

    return { block = horizontalBlock, label = label, button = button }
end

function this.onCreate(container)
    -- Create the main pane for a uniform look.
	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = "top_to_bottom"
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
    mainPane.paddingAllSides = 6

    createConfigSliderPackage({
        parent = mainPane,
        label = "Minimum time between autosaves:",
        config = this.config,
        key = "minimumTimeBetweenAutoSaves",
        min = 1,
        max = 60,
        step = 1,
        jump = 5,
        onUpdate = this.resetAutosaveTimer
    })

    createConfigSliderPackage({
        parent = mainPane,
        label = "Number of autosaves to keep:",
        config = this.config,
        key = "maxSaveCount",
        min = 1,
        max = 100,
        step = 1,
        jump = 5,
    })

    createBooleanConfigPackage({
        parent = mainPane,
        label = "Make quicksave load the latest save instead of the latest quicksave?",
        config = this.config,
        key = "loadLatestSave",
    })

    createBooleanConfigPackage({
        parent = mainPane,
        label = "Create autosaves on a timer?",
        config = this.config,
        key = "saveOnTimer",
    })

    createConfigSliderPackage({
        parent = mainPane,
        label = "Autosave timer duration:",
        config = this.config,
        key = "timeBetweenAutoSaves",
        min = 1,
        max = 60,
        step = 1,
        jump = 5,
        onUpdate = this.resetAutosaveTimer
    })

    createBooleanConfigPackage({
        parent = mainPane,
        label = "Create autosaves when combat starts?",
        config = this.config,
        key = "saveOnCombatStart",
    })

    createBooleanConfigPackage({
        parent = mainPane,
        label = "Create autosaves when combat ends?",
        config = this.config,
        key = "saveOnCombatEnd",
    })

    createBooleanConfigPackage({
        parent = mainPane,
        label = "Create autosaves after changing cells?",
        config = this.config,
        key = "saveOnCellChange",
    })
end

function this.onClose(container)
    mwse.saveConfig("Sophisticated Save System", this.config)
end

return this