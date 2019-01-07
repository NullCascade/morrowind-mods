local common = require("UI Expansion.common")

local hiddenDefaultFields = {
	"^" .. tes3.findGMST(tes3.gmst.sValue).value .. ": ",
	"^" .. tes3.findGMST(tes3.gmst.sWeight).value .. ": ",
	"^" .. tes3.findGMST(tes3.gmst.sCondition).value .. ": ",
}

local enchantmentType = {
	tes3.findGMST(tes3.gmst.sItemCastOnce).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenStrikes).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenUsed).value,
	tes3.findGMST(tes3.gmst.sItemCastConstant).value,
}

local function labelBlock(tooltip, label)
	local block = tooltip:createBlock({})
	block.minWidth = 1
	block.maxWidth = 210
	block.autoWidth = true
	block.autoHeight = true
	block.paddingAllSides = 1
	local blockLabel = block:createLabel{text = label}
	blockLabel.wrapText = true
	return blockLabel
end

local function enchantConditionBlock(tooltip, object, itemData)
	if object.enchantment == nil and object.enchantCapacity > 0 then
		labelBlock(tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, object.enchantCapacity / 10))
	end

	if object.maxCondition ~= nil and object.objectType ~= tes3.objectType.ammunition then
		local block = tooltip:createBlock({})
		block.autoWidth = true
		block.autoHeight = true
		block.paddingAllSides = 4
		block.paddingLeft = 2
		block.paddingRight = 2
		--TODO Temporarily removed the label.
		--block:createLabel{text = string.format("%s:", common.dictionary.condition)}

		block:createFillBar{current = itemData and itemData.condition or object.maxCondition, max = object.maxCondition}
	end

	if object.enchantment then
		-- Check for condition again, otherwise there could be nothing to divide.
		if object.maxCondition ~= nil then
			local divide = tooltip:createDivider()
			divide.widthProportional = 0.85
		end

		tooltip:createLabel{ text = enchantmentType[object.enchantment.castType + 1] }
		for i = 1, #object.enchantment.effects do
			-- effects is a fixed size array, empty slots have the id -1.
			if object.enchantment.effects[i].id >= 0 then
				--magicEffectBlock(tooltip, object.enchantment, object.enchantment.effects[i])
				local block = tooltip:createBlock({})
				block.minWidth = 1
				block.maxWidth = 640
				block.autoWidth = true
				block.autoHeight = true
				block.widthProportional = 1.0
				block.borderAllSides = 1
				block:createImage{ path = string.format("icons\\%s", object.enchantment.effects[i].object.icon) }
				local label = block:createLabel{ text = string.format("%s", object.enchantment.effects[i]) }
				label.borderLeft = 4
				label.wrapText = false
			end
		end

		-- Constant effect enchantments don't have a charge!
		if object.enchantment.castType ~= tes3.enchantmentType.constant then
			local block = tooltip:createBlock({})
			block.autoWidth = true
			block.autoHeight = true
			block.paddingAllSides = 4
			block.paddingLeft = 2
			block.paddingRight = 2

			local fillBar = block:createFillBar{current = itemData and itemData.charge or object.enchantment.maxCharge, max = object.enchantment.maxCharge}
			fillBar.widget.fillColor = tes3ui.getPalette("magic_color")
		end
	end
end

local function replaceWeaponTooltip(tooltip, weapon, itemData)
	for i = #tooltip:getContentElement().children, 3, -1 do
		tooltip:getContentElement().children[i].visible = false
	end

	-- Second index should be 'Type: Axe, Two Handed'
	--TODO: this is not robust
	tooltip:getContentElement().children[2].text = tooltip:getContentElement().children[2].text:gsub(tes3.findGMST(tes3.gmst.sType).value .. " ", "")

	if weapon.isMelee then
		if tes3.worldController.useBestAttack then
			local slashAvg = (weapon.slashMin + weapon.slashMax) / 2
			local thrustAvg = (weapon.thrustMin + weapon.thrustMax) / 2
			local chopAvg = (weapon.chopMin + weapon.chopMax) / 2

			if slashAvg == thrustAvg == chopAvg or slashAvg >= chopAvg and slashAvg >= thrustAvg then
				labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sSlash).value, weapon.slashMin, weapon.slashMax))
			elseif thrustAvg >= chopAvg and thrustAvg >= slashAvg then
				labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sThrust).value, weapon.thrustMin, weapon.thrustMax))
			else
				labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sChop).value, weapon.chopMin, weapon.chopMax))
			end
		else
			labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sSlash).value, weapon.slashMin, weapon.slashMax))
			labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sThrust).value, weapon.thrustMin, weapon.thrustMax))
			labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sChop).value, weapon.chopMin, weapon.chopMax))
		end
	else
		labelBlock(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sAttack).value, weapon.chopMin, weapon.chopMax))
	end

	if not weapon.isAmmo then
		if weapon.speed ~= 1.0 then
			labelBlock(tooltip, string.format("%s: %.2f", common.dictionary.weaponSpeed, weapon.speed))
		end
		if weapon.reach ~= 1.0 then
			labelBlock(tooltip, string.format("%s: %.2f", common.dictionary.weaponReach, weapon.reach))
		end
	end

	enchantConditionBlock(tooltip, weapon, itemData)
end

local function replaceArmorTooltip(tooltip, armor, itemData)
	for i = #tooltip:getContentElement().children, 2, -1 do
		tooltip:getContentElement().children[i].visible = false
	end

	tooltip:createLabel{ text = common.dictionary.weightClasses[armor.weightClass + 1] }
	tooltip:createLabel{ text = string.format("%s: %u", tes3.findGMST(tes3.gmst.sArmorRating).value, armor.armorRating) }

	enchantConditionBlock(tooltip, armor, itemData)
end

local function replaceClothingTooltip(tooltip, clothing, itemData)
	for i = #tooltip:getContentElement().children, 2, -1 do
		tooltip:getContentElement().children[i].visible = false
	end

	enchantConditionBlock(tooltip, clothing, itemData)
end

local function replaceBookTooltip(tooltip, book, itemData)
	for i = #tooltip:getContentElement().children, 2, -1 do
		tooltip:getContentElement().children[i].visible = false
	end
	--TODO: magic number
	if book.type == 1 then
		enchantConditionBlock(tooltip, book, itemData)
	end
end

local function replaceAlchemyTooltip(tooltip, alchemy, itemData)
	for i = #tooltip:getContentElement().children, 2, -1 do
		tooltip:getContentElement().children[i].visible = false
	end

	for i = 1, #alchemy.effects do
		-- effects is a fixed size array, empty slots have the id -1.
		if alchemy.effects[i].id >= 0 then
			--magicEffectBlock(tooltip, object.enchantment, object.enchantment.effects[i])
			local block = tooltip:createBlock({})
			block.minWidth = 1
			block.maxWidth = 640
			block.autoWidth = true
			block.autoHeight = true
			block.widthProportional = 1.0
			block:createImage{ path = string.format("icons\\%s", alchemy.effects[i].object.icon) }
			local label = block:createLabel{ text = string.format("%s", alchemy.effects[i]) }
			label.borderLeft = 4
			label.wrapText = false
		end
	end
end

local function extraTooltip(e)
	-- I believe this is hardcoded in engine, so we'll just do this too.
	if e.object.id:find("Gold_") or e.object.isKey then
		return
	end

	-- Adjust and remove vanilla tooltip fields.
	local parent = e.tooltip.children[1]
	-- Iterate in reverse so we can just destroy the elements as we find them.
	for i = #parent.children, 1, -1 do
		for k, field in pairs(hiddenDefaultFields) do
			if parent.children[i].text:find(field) then
				parent.children[i].visible = false
				break
			end
		end
	end

	-- Add padding to the title.
	e.tooltip:getContentElement().children[1].borderAllSides = 3

	if e.object.objectType == tes3.objectType.weapon or e.object.objectType == tes3.objectType.ammunition then
		replaceWeaponTooltip(e.tooltip, e.object, e.itemData)
	elseif e.object.objectType == tes3.objectType.armor then
		replaceArmorTooltip(e.tooltip, e.object, e.itemData)
	elseif e.object.objectType == tes3.objectType.clothing then
		replaceClothingTooltip(e.tooltip, e.object, e.itemData)
	elseif e.object.objectType == tes3.objectType.book then
		replaceBookTooltip(e.tooltip, e.object, e.itemData)
	elseif e.object.objectType == tes3.objectType.alchemy then
		replaceAlchemyTooltip(e.tooltip, e.object, e.itemData)

	-- Light duration
	elseif e.object.objectType == tes3.objectType.light then
		local blockDurationBar = e.tooltip:createBlock({})
		blockDurationBar.autoWidth = true
		blockDurationBar.autoHeight = true
		blockDurationBar.paddingAllSides = 4
		blockDurationBar.paddingLeft = 2
		blockDurationBar.paddingRight = 2
		blockDurationBar:createLabel{text = string.format("%s:", common.dictionary.lightDuration)}

		local labelDurationBar = blockDurationBar:createFillBar{current = e.itemData and e.itemData.timeLeft or e.object.time, max = e.object.time}
		--TODO see if there's a better color
		--labelDurationBar.widget.fillColor = tes3ui.getPalette("normal_color")
		labelDurationBar.borderLeft = 4

	-- Soul gem capacity
	elseif e.object.isSoulGem then
		local soulValue = tes3.findGMST(tes3.gmst.fSoulGemMult).value * e.object.value
		labelBlock(e.tooltip, string.format("%s: %u", common.dictionary.soulCapacity, soulValue))
	end

	-- Add the value and weight back in.
	if e.object.value and e.object.weight then
		local container = e.tooltip:createBlock({})
		container.widthProportional = 1.0
		container.minHeight = 16
		container.autoHeight = true
		container.paddingAllSides = 2
		container.paddingTop = 4
		container.childAlignX = 1.0

		-- Value
		local block = container:createBlock({})
		block.autoWidth = true
		block.autoHeight = true
		block:createImage{ path = "icons/gold.dds" }
		local label = block:createLabel{ text = string.format("%u", e.object.value) }
		label.borderLeft = 4

		-- Weight
		block = container:createBlock({})
		block.autoWidth = true
		block.autoHeight = true
		block:createImage{ path = "icons/weight.dds" }
		block.borderLeft = 8
		label = block:createLabel{ text = string.format("%.2f", e.object.weight) }
		label.borderLeft = 4

		parent:updateLayout()

		-- Update minimum width of the whole tooltip to make sure there's space for the value/weight.
		e.tooltip:getContentElement().minWidth = 120
		e.tooltip:updateLayout()
	end

	-- Show a tooltip for stolen goods!
	local merchant = tes3ui.getServiceActor()
	if merchant ~= nil and e.object.stolenList ~= nil then
		for i, v in pairs(e.object.stolenList) do
			if merchant.object.name == v.name then
				e.tooltip:createDivider()
				local label = labelBlock(e.tooltip, common.dictionary.stolenFromMerchant)
				label.borderAllSides = 8
				label.justifyText = "center"
				label.color = tes3ui.getPalette("negative_color")
				break
			end
		end
	end
end

event.register("uiObjectTooltip", extraTooltip)