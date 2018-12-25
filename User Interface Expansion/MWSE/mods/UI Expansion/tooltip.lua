local common = require("UI Expansion.common")

--TODO need translation independent solution
local hiddenDefaultFields = {
	"^Value: ",
	"^Weight: ",
	"^Condition: ",
}

local enchantmentType = {
	tes3.findGMST(tes3.gmst.sItemCastOnce).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenStrikes).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenUsed).value,
	tes3.findGMST(tes3.gmst.sItemCastConstant).value,
}

local enchantmentRange = {
	tes3.findGMST(tes3.gmst.sRangeSelf).value,
	tes3.findGMST(tes3.gmst.sRangeTouch).value,
	tes3.findGMST(tes3.gmst.sRangeTarget).value,
}

local function labelBlock(tooltip, label)
	local block = tooltip:createBlock()
	block.minWidth = 1
	block.maxWidth = 210
	block.autoWidth = true
	block.autoHeight = true
	local label = block:createLabel{text = label}
	label.wrapText = true
	return label
end

local function magicEffectName(effect)
	local name = tes3.findGMST(effect.id + 1283).value
	if effect.object.targetsSkills then
		return name:gsub("Skill", tes3.findGMST(effect.skill + 896).value)	--TODO need translation independent solution
	elseif effect.object.targetsAttributes then
		return name:gsub("Attribute", tes3.findGMST(effect.attribute + 888).value)
	end

	return name
end

local function magicEffectDuration(enchantment, effect)
	if effect.object.hasNoDuration or enchantment.castType == tes3.enchantmentType.constant then
		return ""
	end

	return string.format(" %s %u %s", tes3.findGMST(tes3.gmst.sfor).value, effect.duration,
		effect.duration == 1 and tes3.findGMST(tes3.gmst.ssecond).value or tes3.findGMST(tes3.gmst.sseconds).value) 
end

--TODO This still needs to handle % vs pts for some spells
local function magicEffectMagnitude(effect)
	if effect.object.hasNoMagnitude then
		return ""
	elseif effect.min == effect.max then
		return string.format(" %u %s", effect.min,
			effect.min == 1 and tes3.findGMST(tes3.gmst.spoint).value or tes3.findGMST(tes3.gmst.spoints).value)
	else
		return string.format(" %u %s %u %s", effect.min, tes3.findGMST(tes3.gmst.sTo).value, effect.max, tes3.findGMST(tes3.gmst.spoints).value)
	end
end

local function magicEffectRadius(effect)
	if effect.radius == 0 then
		return ""
	end

	return string.format(" %s %u %s", tes3.findGMST(tes3.gmst.sin).value, effect.radius, tes3.findGMST(tes3.gmst.sfeet).value)
end

local function magicEffectTarget(enchantment, effect)
	if enchantment.castType == tes3.enchantmentType.onStrike and effect.rangeType ~= tes3.effectRange.self then
		return ""
	else
		return string.format(" %s %s", tes3.findGMST(tes3.gmst.sonword).value, tes3.findGMST(effect.rangeType + 1442).value)
	end
end


local function magicEffectBlock(tooltip, enchantment, effect)
	local block = tooltip:createBlock()
	block.minWidth = 1
	block.maxWidth = 640
	block.autoWidth = true
	block.autoHeight = true
	block:createImage{ path = string.format("icons\\%s", effect.object.icon) }
	local effectDesc = string.format("%s%s%s%s%s",
		magicEffectName(effect),
		magicEffectMagnitude(effect),
		magicEffectDuration(enchantment, effect),
		magicEffectRadius(effect),
		magicEffectTarget(enchantment, effect))
	local label = block:createLabel{ text = effectDesc }
	label.borderLeft = 4
	label.wrapText = false
end

local function enchantConditionBlock(tooltip, object, itemData)
	if object.enchantment == nil then
		labelBlock(tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, object.enchantCapacity / 10))
	end

	local block = tooltip:createBlock()
	block.autoWidth = true
	block.autoHeight = true
	block.paddingAllSides = 4
	block.paddingLeft = 2
	block.paddingRight = 2
	--TODO Temporarily removed the label.
	--block:createLabel{text = string.format("%s:", common.dictionary.condition)}

	local fillBar = block:createFillBar{current = itemData and itemData.condition or object.maxCondition, max = object.maxCondition}

	if object.enchantment then
		tooltip:createDivider()
		tooltip:createLabel{ text = enchantmentType[object.enchantment.castType + 1] }

		for i = 1, #object.enchantment.effects do
			-- effects is a fixed size array, empty slots have the id -1.
			if object.enchantment.effects[i].id ~= -1 then
				magicEffectBlock(tooltip, object.enchantment, object.enchantment.effects[i])
			end
		end

		-- Constant effect enchantments don't have a charge!
		if object.enchantment.castType ~= tes3.enchantmentType.constant then
			block = tooltip:createBlock()
			block.autoWidth = true
			block.autoHeight = true
			block.paddingAllSides = 4
			block.paddingLeft = 2
			block.paddingRight = 2
		
			fillBar = block:createFillBar{current = itemData and itemData.charge or object.enchantment.maxCharge, max = object.enchantment.maxCharge}
			fillBar.widget.fillColor = tes3ui.getPalette("magic_color")
		end
	end
end

local function replaceWeaponTooltip(tooltip, weapon, itemData)
	for i = #tooltip:getContentElement().children, 3, -1 do
		tooltip:getContentElement().children[i]:destroy()
	end

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

	labelBlock(tooltip, string.format("%s: %.2f", common.dictionary.weaponSpeed, weapon.speed))
	labelBlock(tooltip, string.format("%s: %.2f", common.dictionary.weaponReach, weapon.reach))

	enchantConditionBlock(tooltip, weapon, itemData)
end

local function replaceArmorTooltip(tooltip, armor, itemData)
	for i = #tooltip:getContentElement().children, 2, -1 do
		tooltip:getContentElement().children[i]:destroy()
	end

	tooltip:createLabel{ text = common.dictionary.weightClasses[armor.weightClass + 1] }
	tooltip:createLabel{ text = string.format("%s: %u", tes3.findGMST(tes3.gmst.sArmorRating).value, armor.armorRating) }

	enchantConditionBlock(tooltip, armor, itemData)
end

local function extraTooltip(e)
	--TODO this a) sucks and b) doesn't work for gold piles, and c) there's probably lots of other things this should apply to
	if e.object.id == "Gold_001" then
		return
	end

	-- Adjust and remove vanilla tooltip fields.
	local parent = e.tooltip.children[1]
	-- Iterate in reverse so we can just destroy the elements as we find them.
	for i = #parent.children, 1, -1 do
		-- Trim the type field so it's easier to read.
		if parent.children[i].text:find("^Type: ") then --TODO need translation independent solution
			parent.children[i].text = parent.children[i].text:sub(6)
		else
			for k, field in pairs(hiddenDefaultFields) do --TODO need translation independent solution
				if parent.children[i].text:find(field) then
					parent.children[i]:destroy()
					break
				end
			end
		end
	end

	if e.object.objectType == tes3.objectType.weapon then
		replaceWeaponTooltip(e.tooltip, e.object, e.itemData)

	elseif e.object.objectType == tes3.objectType.armor then
		replaceArmorTooltip(e.tooltip, e.object, e.itemData)

	-- Enchantment capacity (clothing)
	elseif e.object.objectType == tes3.objectType.clothing then
		if e.object.enchantment == nil then
			labelBlock(e.tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, e.object.enchantCapacity / 10))
		end	
	
	-- Light duration
	elseif e.object.objectType == tes3.objectType.light then
		local blockDurationBar = e.tooltip:createBlock()
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
		local container = e.tooltip:createBlock()
		container.widthProportional = 1.0
		container.minHeight = 16
		container.autoHeight = true
		container.paddingAllSides = 2
		container.childAlignX = -1.0

		-- Value
		local block = container:createBlock()
		block.autoWidth = true
		block.autoHeight = true
		block:createImage{ path = "icons/gold.dds" }
		local label = block:createLabel{ text = string.format("%u", e.object.value) }
		label.borderLeft = 4

		-- Weight
		block = container:createBlock()
		block.autoWidth = true
		block.autoHeight = true
		block:createImage{ path = "icons/weight.dds" }
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
				local divider = e.tooltip:createDivider()
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