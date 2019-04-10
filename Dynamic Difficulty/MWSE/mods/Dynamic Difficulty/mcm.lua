local this = {}

-- We'll need the interop library.
local interop = require("Dynamic Difficulty.interop")

local calculationLabel = nil

local function updateCalculationLabel()
    if (tes3.player == nil) then
        return
    end

    -- Add any region modifiers.
    local region = "N/A"
    local regionalMod = 0
	local lastExteriorCell = tes3.getDataHandler().lastExteriorCell
	if (lastExteriorCell ~= nil) then
        if (lastExteriorCell.region ~= nil) then
            region = lastExteriorCell.region.id
			regionalMod = this.config.regionModifiers[lastExteriorCell.region.id] or 0
		end
	end

    calculationLabel.text = string.format(
        "    %d = %d [base] + ( %d [increase per level] * %d [level-1] ) + %d [regional: %s]",
        this.config.baseDifficulty + (tes3.player.object.level - 1) * this.config.increasePerLevel + regionalMod,
        this.config.baseDifficulty,
        this.config.increasePerLevel,
        tes3.player.object.level - 1,
        regionalMod,
        region
    )
end

local function caseInsensitiveSorter(a, b)
	return string.lower(a) < string.lower(b)
end

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
        sliderLabel.text = tostring(config[key])
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
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
    mainPane.paddingAllSides = 6
    
    -- If we're in a game, show the current calculation.
    if (tes3.mobilePlayer) then
        -- Create a label to explain the next line.
        local label = mainPane:createLabel({ text = "Dynamic Difficulty calculation:" })
        label.borderBottom = 6
        
        -- Assign and update the calculation explanation.
        calculationLabel = mainPane:createLabel({ text = "N/A" })
        calculationLabel.borderBottom = 6
        updateCalculationLabel()
    end

    -- Config: Base Difficulty.
    createConfigSliderPackage({
        parent = mainPane,
        label = "Base difficulty:",
        config = this.config,
        key = "baseDifficulty",
        min = -100,
        max = 100,
        step = 1,
        jump = 10,
        onUpdate = updateCalculationLabel
    })

    -- Config: Increase Per Level.
    createConfigSliderPackage({
        parent = mainPane,
        label = "Increase per level (after 1):",
        config = this.config,
        key = "increasePerLevel",
        min = -25,
        max = 25,
        step = 1,
        jump = 5,
        onUpdate = updateCalculationLabel
    })

    -- Config: Cap Difficulty.
    do
		local horizontalBlock = mainPane:createBlock({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.layoutWidthFraction = 1.0
		horizontalBlock.height = 24
	
		local label = horizontalBlock:createLabel({ text = "Cap difficulty between -100 and 100?" })
		label.layoutOriginFractionX = 0.0
        label.layoutOriginFractionY = 0.5

		local button = horizontalBlock:createButton({ text = (this.config.capDifficulty and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value) })
		button.layoutOriginFractionX = 1.0
        button.layoutOriginFractionY = 0.5
		button.paddingTop = 3
        button:register("mouseClick", function(e)
            this.config.capDifficulty = not this.config.capDifficulty
            button.text = this.config.capDifficulty and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
        end)
    end

    -- Config: Regional Modifiers
    do
        local label = mainPane:createLabel({ text = "Regional modifiers:" })
        label.borderBottom = 3
        label.borderTop = 6

        -- Create the scroll pane that regions will live in.
		local regionList = mainPane:createVerticalScrollPane({})
		regionList.layoutWidthFraction = 1.0
		regionList.layoutHeightFraction = 1.0
        regionList.paddingAllSides = 6
        
        -- Build a list of regions, then sort them.
        local regionsArray = {}
        for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
            table.insert(regionsArray, region.id)
        end
        table.sort(regionsArray, caseInsensitiveSorter)

        -- Then build a slider list for them.
        for i = 1, #regionsArray do
            local regionId = regionsArray[i]
            local elements = createConfigSliderPackage({
                parent = regionList,
                label = string.format("%s:", regionId),
                config = this.config.regionModifiers,
                key = regionId,
                default = 0,
                min = -100,
                max = 100,
                step = 1,
                jump = 5,
                onUpdate = updateCalculationLabel
            })
            elements.slider.borderRight = 6
            elements.sliderLabel.borderRight = 312
        end
    end
end

function this.onClose(container)
    mwse.saveConfig("Dynamic Difficulty", this.config)
    interop.recalculate()
end

return this