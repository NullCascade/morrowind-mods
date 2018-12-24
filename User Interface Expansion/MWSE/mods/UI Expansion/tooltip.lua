local this = {}

local common = require("UI Expansion.common")

local function tooltipBlock(tooltip, label)
	local block = tooltip:createBlock()
	block.minWidth = 1
	block.maxWidth = 210
	block.autoWidth = true
	block.autoHeight = true
	local label = block:createLabel{text = label}
	label.wrapText = true
	return label
end

local function extraTooltip(e)
	-- Remove weight and value.
	local parent = e.tooltip.children[1]
	-- Iterate in reverse so we can just destroy the elements as we find them.
	for i = #parent.children, 1, -1 do
		if parent.children[i].text:find("^Value: ") or parent.children[i].text:find("^Weight: ") then
			parent.children[i]:destroy()
		end
	end

	-- Weapon specific stats
	if e.object.objectType == tes3.objectType.weapon then
		tooltipBlock(e.tooltip, string.format("%s: %.2f", common.dictionary.weaponSpeed, e.object.speed))
		tooltipBlock(e.tooltip, string.format("%s: %.2f", common.dictionary.weaponReach, e.object.reach))
	end

	-- Enchantment capacity (weapons, armor, clothing)
	if e.object.objectType == tes3.objectType.weapon or
	e.object.objectType == tes3.objectType.armor or
	e.object.objectType == tes3.objectType.clothing then
		if e.object.enchantment == nil then
			tooltipBlock(e.tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, e.object.enchantCapacity / 10))
		end
	
	-- Light duration
	elseif e.object.objectType == tes3.objectType.light then
		local maxDuration = e.object.time
		local duration
		if e.itemData or e.reference then
			duration = e.object:getTimeLeft(e.itemData or e.reference)
		else
			duration = e.object.time
		end

		local blockDurationBar = e.tooltip:createBlock()
		blockDurationBar.autoWidth = true
		blockDurationBar.autoHeight = true
		blockDurationBar.paddingAllSides = 10
		blockDurationBar:createLabel{text = string.format("%s:", common.dictionary.lightDuration)}

		local labelDurationBar = blockDurationBar:createFillBar{current = duration, max = maxDuration}
		--labelDurationBar.widget.fillColor = tes3ui.getPalette("normal_color")
		labelDurationBar.borderLeft = 4

	-- Soul gem capacity
	elseif e.object.isSoulGem then
		local soulValue = tes3.findGMST(tes3.gmst.fSoulGemMult).value * e.object.value
		tooltipBlock(e.tooltip, string.format("%s: %u", common.dictionary.soulCapacity, soulValue))
	end

	-- Add the value and weight back in.
	if e.object.value and e.object.weight then
		local container = e.tooltip:createBlock()
		container.widthProportional = 1.0
		container.minHeight = 16
		container.autoHeight = true
		container.borderAllSides = 4
		container.childAlignX = -1.0

		-- Value
		local block = container:createBlock()
		block.autoWidth = true
		block.autoHeight = true
		block:createImage{ path = "icons/gold.dds" }
		local label = block:createLabel{ text = string.format("%u", e.object.value) }
		label.borderLeft = 4
		label.borderRight = 4

		-- Weight
		block = container:createBlock()
		block.autoWidth = true
		block.autoHeight = true
		block:createImage{ path = "icons/tx_goldicon.dds" }
		label = block:createLabel{ text = string.format("%.2f", e.object.weight) }
		label.borderLeft = 4
		label.borderRight = 4

		parent:updateLayout()
	end

	-- Show a tooltip for stolen goods!
	local merchant = tes3ui.getServiceActor()
	if merchant ~= nil and e.object.stolenList ~= nil then
		for i, v in pairs(e.object.stolenList) do
			if merchant.object.name == v.name then
				local divider = e.tooltip:createDivider()
				local label = tooltipBlock(e.tooltip, common.dictionary.stolenFromMerchant)
				label.borderAllSides = 8
				label.justifyText = "center"
				label.color = tes3ui.getPalette("negative_color")
				break
			end 
		end
	end

	-- Update minimum width of the whole tooltip to account for the missing value/weight fields.
end

event.register("uiObjectTooltip", extraTooltip)