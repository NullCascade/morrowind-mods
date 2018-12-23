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
	return {block, label}
end

local function extraTooltip(e)
	local speed, reach, duration, enchValue, maxDuration

	-- Show a tooltip for stolen goods!
	local merchant = tes3ui.getServiceActor()
	if merchant ~= nil and e.object.stolenList ~= nil then
		for i, v in pairs(e.object.stolenList) do
			if merchant.object.name == v.name then
				local bag = {block, label}
				bag = tooltipBlock(e.tooltip, common.dictionary.stolenFromMerchant)
				bag.label.borderAllSides = 8
				bag.label.justifyText = "center"
				bag.label.color = tes3ui.getPalette("negative_color")
				break
			end 
		end
	end

	if e.object.objectType == tes3.objectType.weapon then
		speed = e.object.speed
		reach = e.object.reach
		enchValue = e.object.enchantCapacity / 10

	elseif e.object.objectType == tes3.objectType.armor or e.object.objectType == tes3.objectType.clothing then
		enchValue = e.object.enchantCapacity / 10

	elseif e.object.objectType == tes3.objectType.light then
		maxDuration = e.object.time

		if e.itemData or e.reference then
			duration = e.object:getTimeLeft(e.itemData or e.reference)
		else
			duration = e.object.time
		end
	end

	if e.object.objectType == tes3.objectType.weapon then
		tooltipBlock(e.tooltip, string.format("%s: %.2f", common.dictionary.weaponSpeed, speed))
		tooltipBlock(e.tooltip, string.format("%s: %.2f", common.dictionary.weaponReach, reach))

		if e.object.enchantment == nil then
			tooltipBlock(e.tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, enchValue))
		end

	elseif e.object.objectType == tes3.objectType.armor or e.object.objectType == tes3.objectType.clothing then
		if e.object.enchantment == nil then
			tooltipBlock(e.tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, enchValue))
		end
		
	elseif e.object.objectType == tes3.objectType.light then
		local blockDurationBar = e.tooltip:createBlock()
		blockDurationBar.autoWidth = true
		blockDurationBar.autoHeight = true
		blockDurationBar.paddingAllSides = 10
		local labelDuration = blockDurationBar:createLabel{text = string.format("%s:", common.dictionary.lightDuration)}
		local labelDurationBar = blockDurationBar:createFillBar {current = duration, max = maxDuration}
		labelDurationBar.widget.fillColor = tes3ui.getPalette("normal_color")
		labelDurationBar.borderLeft = 4

	elseif e.object.isSoulGem then
		local soulValue = tes3.findGMST(tes3.gmst.fSoulGemMult).value * e.object.value
		tooltipBlock(e.tooltip, string.format("%s: %u", common.dictionary.soulCapacity, soulValue))
	end
end

event.register("uiObjectTooltip", extraTooltip)