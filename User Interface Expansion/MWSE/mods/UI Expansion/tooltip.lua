local GUI_ID_TooltipIconBar				= tes3ui.registerID("UIEXP_Tooltip_IconBar")
local GUI_ID_TooltipIconGoldBlock		= tes3ui.registerID("UIEXP_Tooltip_IconGoldBlock")
local GUI_ID_TooltipIconWeightBlock		= tes3ui.registerID("UIEXP_Tooltip_IconWeightBlock")
local GUI_ID_TooltipExtraDivider		= tes3ui.registerID("UIEXP_Tooltip_ExtraDivider")
local GUI_ID_TooltipEnchantmentDivider	= tes3ui.registerID("UIEXP_Tooltip_EnchantmentDivider")
local GUI_ID_TooltipEnchantCapacity		= tes3ui.registerID("UIEXP_Tooltip_EnchantCapacity")
local GUI_ID_TooltipSpeed				= tes3ui.registerID("UIEXP_Tooltip_Speed")
local GUI_ID_TooltipReach				= tes3ui.registerID("UIEXP_Tooltip_Reach")
local GUI_ID_TooltipWeightClass			= tes3ui.registerID("UIEXP_Tooltip_WeightClass")
local GUI_ID_TooltipStolenLabel			= tes3ui.registerID("UIEXP_Tooltip_StolenLabel")

local common = require("UI Expansion.common")

local enchantmentType = {
	tes3.findGMST(tes3.gmst.sItemCastOnce).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenStrikes).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenUsed).value,
	tes3.findGMST(tes3.gmst.sItemCastConstant).value,
}

local function tryDestroyID(tooltip, uiid)
	local element = tooltip:findChild(tes3ui.registerID(uiid))
	if element ~= nil then
		element:destroy()
		return true
	end
	return false
end

local function tryDestroyAllID(tooltip, uiid)
	while true do
		local element = tooltip:findChild(tes3ui.registerID(uiid))
		if element ~= nil then
			element:destroy()
		else
			return
		end
	end
end

local function tryHideID(tooltip, uiid)
	local element = tooltip:findChild(tes3ui.registerID(uiid))
	if element ~= nil then
		element.visible = false
		return true
	end
	return false
end

local function labelFormatted(tooltip, label, uiid)
	local block
	if uiid ~= nil then
		if type(uiid) == "string" then
			block = tooltip:createLabel{ text = label, id = tes3ui.registerID(uiid) }
		else
			block = tooltip:createLabel{ text = label, id = uiid }
		end
	else
		block = tooltip:createLabel{ text = label }
	end
	block.minWidth = 1
	block.maxWidth = 210
	block.autoWidth = true
	block.autoHeight = true
	block.paddingAllSides = 1
	return block
end

local function enchantConditionBlock(tooltip, object, itemData)
	if object.enchantment == nil and math.floor(object.enchantCapacity * 0.1) > 0 then
		labelFormatted(tooltip, string.format("%s: %u", common.dictionary.enchantCapacity, object.enchantCapacity / 10), GUI_ID_TooltipEnchantCapacity)
	end

	if object.maxCondition ~= nil and object.objectType ~= tes3.objectType.ammunition then
		-- Destroy the old condition block, and replace it.
		tryDestroyID(tooltip, "HelpMenu_qualityCondition")

		local block = tooltip:createBlock{ id = tes3ui.registerID("HelpMenu_qualityCondition") }
		block.autoWidth = true
		block.autoHeight = true
		block.paddingAllSides = 4
		block.paddingLeft = 2
		block.paddingRight = 2

		block:createFillBar{current = itemData and itemData.condition or object.maxCondition, max = object.maxCondition}
	end

	if object.enchantment then
		tryDestroyID(tooltip, "HelpMenu_castType")
		tryDestroyID(tooltip, "HelpMenu_enchantmentContainer")

		-- Check for condition again, otherwise there could be nothing to divide.
		if object.maxCondition ~= nil then
			local divide = tooltip:createDivider{ id = GUI_ID_TooltipEnchantmentDivider }
			divide.widthProportional = 0.85
		end

		tooltip:createLabel{ text = enchantmentType[object.enchantment.castType + 1], id = tes3ui.registerID("HelpMenu_castType") }
		local enchantContainer = tooltip:createBlock{ id = tes3ui.registerID("HelpMenu_enchantmentContainer") }
		enchantContainer.flowDirection = "top_to_bottom"
		enchantContainer.autoWidth = true
		enchantContainer.autoHeight = true
		for i = 1, #object.enchantment.effects do
			-- effects is a fixed size array, empty slots have the id -1.
			if object.enchantment.effects[i].id >= 0 then
				local block = enchantContainer:createBlock{ id = tes3ui.registerID("HelpMenu_enchantEffectBlock") }
				block.minWidth = 1
				block.maxWidth = 640
				block.autoWidth = true
				block.autoHeight = true
				block.widthProportional = 1.0
				block.borderAllSides = 1
				block:createImage{ path = string.format("icons\\%s", object.enchantment.effects[i].object.icon), id = tes3ui.registerID("image") }
				local label = block:createLabel{ text = string.format("%s", object.enchantment.effects[i]), id = tes3ui.registerID("HelpMenu_enchantEffectLabel") }
				label.borderLeft = 4
				label.wrapText = false
			end
		end

		-- Constant effect and Cast Once enchantments don't have a charge!
		if object.enchantment.castType ~= tes3.enchantmentType.constant
		and object.enchantment.castType ~= tes3.enchantmentType.castOnce then
			local block = tooltip:createBlock{ id = tes3ui.registerID("HelpMenu_chargeBlock") }
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
	tryDestroyID(tooltip, "HelpMenu_slash")
	tryDestroyID(tooltip, "HelpMenu_chop")
	tryDestroyID(tooltip, "HelpMenu_thrust")

	-- Strip out "Type:", as it's very much self explanatory.
	local weaponType = tooltip:findChild(tes3ui.registerID("HelpMenu_weaponType"))
	weaponType.text = weaponType.text:gsub(tes3.findGMST(tes3.gmst.sType).value .. " ", "")

	if weapon.isMelee then
		if tes3.worldController.useBestAttack then
			local slashAvg = (weapon.slashMin + weapon.slashMax) / 2
			local thrustAvg = (weapon.thrustMin + weapon.thrustMax) / 2
			local chopAvg = (weapon.chopMin + weapon.chopMax) / 2

			if slashAvg >= chopAvg and slashAvg >= thrustAvg then
				labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sSlash).value, weapon.slashMin, weapon.slashMax), "HelpMenu_slash")
			elseif thrustAvg >= chopAvg and thrustAvg >= slashAvg then
				labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sThrust).value, weapon.thrustMin, weapon.thrustMax), "HelpMenu_thrust")
			else
				labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sChop).value, weapon.chopMin, weapon.chopMax), "HelpMenu_chop")
			end
		else
			labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sSlash).value, weapon.slashMin, weapon.slashMax), "HelpMenu_slash")
			labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sThrust).value, weapon.thrustMin, weapon.thrustMax), "HelpMenu_thrust")
			labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sChop).value, weapon.chopMin, weapon.chopMax), "HelpMenu_chop")
		end
	else
		labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sAttack).value, weapon.chopMin, weapon.chopMax), "HelpMenu_thrust")
	end

	if not weapon.isAmmo then
		if weapon.speed ~= 1.0 then
			labelFormatted(tooltip, string.format("%s: %.2f", common.dictionary.weaponSpeed, weapon.speed), GUI_ID_TooltipSpeed)
		end
		if weapon.reach ~= 1.0 then
			labelFormatted(tooltip, string.format("%s: %.2f", common.dictionary.weaponReach, weapon.reach), GUI_ID_TooltipReach)
		end
	end

	enchantConditionBlock(tooltip, weapon, itemData)
end

local function replaceArmorTooltip(tooltip, armor, itemData)
	tryDestroyAllID(tooltip, "HelpMenu_armorRating")

	tooltip:createLabel{ text = common.dictionary.weightClasses[armor.weightClass + 1], id = GUI_ID_TooltipWeightClass }
	tooltip:createLabel{ text = string.format("%s: %u", tes3.findGMST(tes3.gmst.sArmorRating).value, armor:calculateArmorRating(tes3.mobilePlayer)), id = tes3ui.registerID("HelpMenu_armorRating") }

	enchantConditionBlock(tooltip, armor, itemData)
end

local function replaceAlchemyTooltip(tooltip, alchemy, itemData)
	tryDestroyAllID(tooltip, "HelpMenu_effectBlock")

	for i = 1, #alchemy.effects do
		-- effects is a fixed size array, empty slots have the id -1.
		if alchemy.effects[i].id >= 0 then
			local block = tooltip:createBlock{ id = tes3ui.registerID("HelpMenu_effectBlock") }
			block.minWidth = 1
			block.maxWidth = 640
			block.autoWidth = true
			block.autoHeight = true
			block.widthProportional = 1.0
			block:createImage{ path = string.format("icons\\%s", alchemy.effects[i].object.icon), id = tes3ui.registerID("HelpMenu_effectIcon") }
			local label = block:createLabel{ text = string.format("%s", alchemy.effects[i]), id = tes3ui.registerID("HelpMenu_effectLabel") }
			label.borderLeft = 4
			label.wrapText = false
		end
	end
end

local function extraTooltipEarly(e)
	-- I believe this is hardcoded in engine, so we'll just do this too.
	if not e.object.id:find("Gold_") and not e.object.isKey then
		tryHideID(e.tooltip, "HelpMenu_value")
		tryHideID(e.tooltip, "HelpMenu_weight")

		-- Add padding to the title.
		e.tooltip:getContentElement().children[1].borderAllSides = 3

		if e.object.objectType == tes3.objectType.weapon or e.object.objectType == tes3.objectType.ammunition then
			replaceWeaponTooltip(e.tooltip, e.object, e.itemData)
		elseif e.object.objectType == tes3.objectType.armor then
			replaceArmorTooltip(e.tooltip, e.object, e.itemData)
		elseif e.object.objectType == tes3.objectType.clothing then
			enchantConditionBlock(e.tooltip, e.object, e.itemData)
		elseif e.object.objectType == tes3.objectType.book then
			if e.object.type == tes3.bookType.scroll then
				enchantConditionBlock(e.tooltip, e.object, e.itemData)
			end
		elseif e.object.objectType == tes3.objectType.alchemy then
			replaceAlchemyTooltip(e.tooltip, e.object, e.itemData)

		-- Light duration
		elseif e.object.objectType == tes3.objectType.light then
			if e.object.time > 0 then
				local blockDurationBar = e.tooltip:createBlock()
				blockDurationBar.autoWidth = true
				blockDurationBar.autoHeight = true
				blockDurationBar.paddingAllSides = 4
				blockDurationBar.paddingLeft = 2
				blockDurationBar.paddingRight = 2
				blockDurationBar:createLabel{ text = string.format("%s:", common.dictionary.lightDuration) }

				local labelDurationBar = blockDurationBar:createFillBar{ current = e.itemData and e.itemData.timeLeft or e.object.time, max = e.object.time }
				labelDurationBar.borderLeft = 4
			end

		-- Soul gem capacity
		elseif e.object.isSoulGem then
			local soulValue = tes3.findGMST(tes3.gmst.fSoulGemMult).value * e.object.value
			labelFormatted(e.tooltip, string.format("%s: %u", common.dictionary.soulCapacity, soulValue))
		end

		-- Add the value and weight back in.
		if e.object.value and e.object.weight then
			local container = e.tooltip:createBlock{ id = GUI_ID_TooltipIconBar }
			container.widthProportional = 1.0
			container.minHeight = 16
			container.autoHeight = true
			container.paddingAllSides = 2
			container.paddingTop = 4
			container.childAlignX = 1.0

			-- Value
			local block = container:createBlock{ id = GUI_ID_TooltipIconGoldBlock }
			block.autoWidth = true
			block.autoHeight = true
			block:createImage{ path = "icons/gold.dds" }
			local label = block:createLabel{ text = string.format("%u", e.object.value) }
			label.borderLeft = 4

			-- Weight
			block = container:createBlock{ id = GUI_ID_TooltipIconWeightBlock }
			block.autoWidth = true
			block.autoHeight = true
			block:createImage{ path = "icons/weight.dds" }
			block.borderLeft = 8
			label = block:createLabel{ text = string.format("%.2f", e.object.weight) }
			label.borderLeft = 4

			-- Update minimum width of the whole tooltip to make sure there's space for the value/weight.
			e.tooltip:getContentElement().minWidth = 120
			e.tooltip:updateLayout()
		end

		-- Show a tooltip for stolen goods!
		local merchant = tes3ui.getServiceActor()
		if merchant ~= nil and e.object.stolenList ~= nil then
			for _, v in pairs(e.object.stolenList) do
				if merchant.object.name == v.name then
					e.tooltip:createDivider()
					local labelBlock = e.tooltip:createBlock{ id = GUI_ID_TooltipStolenLabel }
					labelBlock.minWidth = 1
					labelBlock.maxWidth = 210
					labelBlock.autoWidth = true
					labelBlock.autoHeight = true
					labelBlock.paddingAllSides = 1
					local label = labelBlock:createLabel{ text = common.dictionary.stolenFromMerchant }
					label.wrapText = true
					label.borderAllSides = 6
					label.justifyText = "center"
					label.color = tes3ui.getPalette("negative_color")
					break
				end
			end
		end
	end

	-- Create an extra divider to look good with flavor text underneath. We'll show this in the lateTooltip if it's needed.
	local divide = e.tooltip:createDivider({ id = GUI_ID_TooltipExtraDivider })
	divide.widthProportional = 0.85
	divide.visible = false
end

local function extraTooltipLate(e)
	local element = e.tooltip:getContentElement()
	local children = element.children

	-- If our divider isn't the last element, then something else was added, like flavor text.
	if children[#children].id ~= GUI_ID_TooltipExtraDivider then
		local divide = element:findChild(GUI_ID_TooltipExtraDivider)
		divide.visible = true
	end

	-- Now, we'll make sure our icon bar is in the position we want (currently the very bottom).
	--TODO: add MCM option to set the position of the iconbar. Top, above enchants, above flavortext, bottom.
	for i = #children, 1, -1 do
		if children[i].id == GUI_ID_TooltipIconBar then
			element:reorderChildren(#children, i - 1, 1)
			break
		end
	end
end

-- Register our events, one early, and one late.
event.register("uiObjectTooltip", extraTooltipEarly, {priority = 100})
event.register("uiObjectTooltip", extraTooltipLate, {priority = -100})

local function onItemTileUpdated(e)
	-- Show an indicator for stolen goods!
	local merchant = tes3ui.getServiceActor()
	if merchant ~= nil and e.item.stolenList ~= nil then
		for _, v in pairs(e.item.stolenList) do
			if merchant.object.name == v.name then
				local icon = e.element:createImage({ path = "icons/ui_exp/ownership_indicator.dds" })
				icon.consumeMouseEvents = false
				icon.width = 16
				icon.height = 16
				icon.scaleMode = true
				icon.absolutePosAlignX = 0.2
				icon.absolutePosAlignY = 0.75
				break
			end
		end
	end
end
event.register("itemTileUpdated", onItemTileUpdated, {filter = "MenuInventory"})