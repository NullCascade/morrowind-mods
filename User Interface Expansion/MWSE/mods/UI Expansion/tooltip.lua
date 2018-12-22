local this = {}

local common = require("UI Expansion.common")

local function extraTooltip(e)
	local speed, reach, duration, enchValue, maxDuration

	-- Show a tooltip for stolen goods!
	local merchant = tes3ui.getServiceActor()
	if merchant ~= nil and e.object.stolenList ~= nil then
		for i, v in pairs(e.object.stolenList) do
			if merchant.object.name == v.name then
				local blockStolen = e.tooltip:createBlock()
				blockStolen.minWidth = 1
				blockStolen.maxWidth = 210
				blockStolen.autoWidth = true
				blockStolen.autoHeight = true
				local labelStolen = blockStolen:createLabel{text = common.dictionary.stolenFromMerchant}
				labelStolen.borderAllSides = 8
				labelStolen.wrapText = true
				labelStolen.justifyText = "center"
				labelStolen.color = tes3ui.getPalette("negative_color")
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
		local blockSpeed = e.tooltip:createBlock()
		blockSpeed.minWidth = 1
		blockSpeed.maxWidth = 210
		blockSpeed.autoWidth = true
		blockSpeed.autoHeight = true
		local labelSpeed = blockSpeed:createLabel{text = string.format("%s: %.2f", common.dictionary.weaponSpeed, speed)}
		labelSpeed.wrapText = true

		local blockReach = e.tooltip:createBlock()
		blockReach.minWidth = 1
		blockReach.maxWidth = 210
		blockReach.autoWidth = true
		blockReach.autoHeight = true
		local labelReach = blockReach:createLabel{text = string.format("%s: %.2f", common.dictionary.weaponReach, reach)}
		labelReach.wrapText = true

		if e.object.enchantment == nil then
			local blockEnch = e.tooltip:createBlock()
			blockEnch.minWidth = 1
			blockEnch.maxWidth = 210
			blockEnch.autoWidth = true
			blockEnch.autoHeight = true
			local labelEnch = blockEnch:createLabel{text = string.format("%s: %u", common.dictionary.enchantCapacity, enchValue)}
			labelEnch.wrapText = true
		end

	elseif e.object.objectType == tes3.objectType.armor or e.object.objectType == tes3.objectType.clothing then
		if e.object.enchantment == nil then
			local blockEnch = e.tooltip:createBlock()
			blockEnch.minWidth = 1
			blockEnch.maxWidth = 210
			blockEnch.autoWidth = true
			blockEnch.autoHeight = true
			local labelEnch = blockEnch:createLabel{text = string.format("%s: %u", common.dictionary.enchantCapacity, enchValue)}
			labelEnch.wrapText = true
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

		local blockSoulSize = e.tooltip:createBlock()
		blockSoulSize.minWidth = 1
		blockSoulSize.maxWidth = 210
		blockSoulSize.autoWidth = true
		blockSoulSize.autoHeight = true
		local labelSoulSize = blockSoulSize:createLabel{text = string.format("%s: %u", common.dictionary.soulCapacity, soulValue)}
		labelSoulSize.wrapText = true
	end
end

event.register("uiObjectTooltip", extraTooltip)