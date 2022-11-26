local GUI_ID_TooltipIconBar = tes3ui.registerID("UIEXP_Tooltip_IconBar")
local GUI_ID_TooltipIconGoldBlock = tes3ui.registerID("UIEXP_Tooltip_IconGoldBlock")
local GUI_ID_TooltipIconWeightBlock = tes3ui.registerID("UIEXP_Tooltip_IconWeightBlock")
local GUI_ID_TooltipIconRatioBlock = tes3ui.registerID("UIEXP_Tooltip_IconRatioBlock")
local GUI_ID_TooltipExtraDivider = tes3ui.registerID("UIEXP_Tooltip_ExtraDivider")
local GUI_ID_TooltipEnchantmentDivider = tes3ui.registerID("UIEXP_Tooltip_EnchantmentDivider")
local GUI_ID_TooltipEnchantCapacity = tes3ui.registerID("UIEXP_Tooltip_EnchantCapacity")
local GUI_ID_TooltipSpeed = tes3ui.registerID("UIEXP_Tooltip_Speed")
local GUI_ID_TooltipReach = tes3ui.registerID("UIEXP_Tooltip_Reach")
local GUI_ID_TooltipWeightClass = tes3ui.registerID("UIEXP_Tooltip_WeightClass")
local GUI_ID_TooltipStolenLabel = tes3ui.registerID("UIEXP_Tooltip_StolenLabel")

local common = require("UI Expansion.common")

local enchantmentType = {
	tes3.findGMST(tes3.gmst.sItemCastOnce).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenStrikes).value,
	tes3.findGMST(tes3.gmst.sItemCastWhenUsed).value,
	tes3.findGMST(tes3.gmst.sItemCastConstant).value,
}

--- Tries to destroy a child with a given UI ID.
--- @param tooltip tes3uiElement
--- @param uiid number|string
--- @return boolean destroyed
local function tryDestroyID(tooltip, uiid)
	local element = tooltip:findChild(uiid)
	if element ~= nil then
		element:destroy()
		return true
	end
	return false
end

--- Destroys all children with a given UI ID.
--- @param tooltip tes3uiElement
--- @param uiid number|string
local function tryDestroyAllID(tooltip, uiid)
	while true do
		local element = tooltip:findChild(uiid)
		if element ~= nil then
			element:destroy()
		else
			return
		end
	end
end

--- Tries to hide an element with a given ID.
--- @param tooltip tes3uiElement
--- @param uiid number|string
--- @return boolean
local function tryHideID(tooltip, uiid)
	local element = tooltip:findChild(uiid)
	if element ~= nil then
		element.visible = false
		return true
	end
	return false
end

--- Creates a label with a specific size.
--- @param tooltip tes3uiElement
--- @param label string
--- @param uiid number|string?
--- @return tes3uiElement
local function labelFormatted(tooltip, label, uiid)
	local block = tooltip:createLabel({ text = label, id = uiid })
	block.minWidth = 1
	block.maxWidth = 210
	block.autoWidth = true
	block.autoHeight = true
	block.paddingAllSides = 1
	return block
end

--- Creates blocks for enchantment and condition information.
--- @param tooltip tes3uiElement
--- @param object tes3item|tes3armor|tes3weapon
--- @param itemData tes3itemData
local function enchantConditionBlock(tooltip, object, itemData)
	if object.enchantment == nil and math.floor(object.enchantCapacity * 0.1) > 0 then
		labelFormatted(tooltip, string.format("%s: %u", common.i18n("tooltip.enchantCapacity"), object.enchantCapacity / 10), GUI_ID_TooltipEnchantCapacity)
	end

	if object.maxCondition ~= nil and object.hasDurability ~= false then
		-- Destroy the old condition block, and replace it.
		tryDestroyID(tooltip, "HelpMenu_qualityCondition")

		local block = tooltip:createBlock({ id = "HelpMenu_qualityCondition" })
		block.autoWidth = true
		block.autoHeight = true
		block.paddingAllSides = 4
		block.paddingLeft = 2
		block.paddingRight = 2

		block:createFillBar({
			current = itemData and itemData.condition or object.maxCondition,
			max = object.maxCondition
		})
	end

	if object.enchantment then
		tryDestroyID(tooltip, "HelpMenu_castType")
		tryDestroyID(tooltip, "HelpMenu_enchantmentContainer")

		-- Check for condition again, otherwise there could be nothing to divide.
		if object.maxCondition ~= nil then
			local divide = tooltip:createDivider({ id = GUI_ID_TooltipEnchantmentDivider })
			divide.widthProportional = 0.85
		end

		tooltip:createLabel({ text = enchantmentType[object.enchantment.castType + 1], id = "HelpMenu_castType" })
		local enchantContainer = tooltip:createBlock({ id = "HelpMenu_enchantmentContainer" })
		enchantContainer.flowDirection = "top_to_bottom"
		enchantContainer.autoWidth = true
		enchantContainer.autoHeight = true
		enchantContainer.borderAllSides = 4
		enchantContainer.borderLeft = 6
		enchantContainer.borderRight = 6

		for i = 1, #object.enchantment.effects do
			-- effects is a fixed size array, empty slots have the id -1.
			if object.enchantment.effects[i].id >= 0 then
				local block = enchantContainer:createBlock({ id = "HelpMenu_enchantEffectBlock" })
				block.minWidth = 1
				block.maxWidth = 640
				block.autoWidth = true
				block.autoHeight = true
				block.widthProportional = 1.0
				block.borderAllSides = 1

				local icon = block:createImage({
					id = "image",
					path = string.format("icons\\%s", object.enchantment.effects[i].object.icon),
				})
				icon.borderTop = 1
				icon.borderRight = 6
				local label = block:createLabel({
					text = string.format("%s", object.enchantment.effects[i]),
					id = "HelpMenu_enchantEffectLabel",
				})
				label.wrapText = false
			end
		end

		-- Constant effect and Cast Once enchantments don't have a charge!
		if object.enchantment.castType ~= tes3.enchantmentType.constant and object.enchantment.castType ~=
		tes3.enchantmentType.castOnce then
			local block = tooltip:createBlock({ id = "HelpMenu_chargeBlock" })
			block.autoWidth = true
			block.autoHeight = true
			block.paddingAllSides = 4
			block.paddingLeft = 2
			block.paddingRight = 2

			local fillBar = block:createFillBar({
				current = itemData and itemData.charge or object.enchantment.maxCharge,
				max = object.enchantment.maxCharge,
			})
			fillBar.widget.fillColor = tes3ui.getPalette("magic_color")
		end
	end
end

--- Replaces information on a weapon's displayed stats.
--- @param tooltip tes3uiElement
--- @param weapon tes3weapon
--- @param itemData tes3itemData
local function replaceWeaponTooltip(tooltip, weapon, itemData)
	tryDestroyID(tooltip, "HelpMenu_slash")
	tryDestroyID(tooltip, "HelpMenu_chop")
	tryDestroyID(tooltip, "HelpMenu_thrust")

	-- Strip out "Type:", as it's very much self explanatory.
	local weaponType = tooltip:findChild("HelpMenu_weaponType")
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
			labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sChop).value, weapon.chopMin, weapon.chopMax), "HelpMenu_chop")
			labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sSlash).value, weapon.slashMin, weapon.slashMax), "HelpMenu_slash")
			labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sThrust).value, weapon.thrustMin, weapon.thrustMax), "HelpMenu_thrust")
		end
	else
		labelFormatted(tooltip, string.format("%s: %u - %u", tes3.findGMST(tes3.gmst.sAttack).value, weapon.chopMin, weapon.chopMax), "HelpMenu_thrust")
	end

	if not weapon.isAmmo then
		if weapon.speed ~= 1.0 then
			labelFormatted(tooltip, string.format("%s: %.2f", common.i18n("tooltip.weapon.speed"), weapon.speed), GUI_ID_TooltipSpeed)
		end
		if weapon.reach ~= 1.0 then
			labelFormatted(tooltip, string.format("%s: %.2f", common.i18n("tooltip.weapon.reach"), weapon.reach), GUI_ID_TooltipReach)
		end
	end

	enchantConditionBlock(tooltip, weapon, itemData)
end

--- Replaces information on an armor's displayed stats.
--- @param tooltip tes3uiElement
--- @param armor tes3armor
--- @param itemData tes3itemData
local function replaceArmorTooltip(tooltip, armor, itemData)
	tryDestroyAllID(tooltip, "HelpMenu_armorRating")

	tooltip:createLabel({
		text = common.i18n("tooltip.armor.weightClass." .. armor.weightClass + 1),
		id = GUI_ID_TooltipWeightClass,
	})
	tooltip:createLabel({
		text = string.format("%s: %u", tes3.findGMST(tes3.gmst.sArmorRating).value, armor:calculateArmorRating(tes3.mobilePlayer)),
		id = "HelpMenu_armorRating",
	})

	enchantConditionBlock(tooltip, armor, itemData)
end

local useMCPShowAllStandardPotionEffects = tes3.hasCodePatchFeature(tes3.codePatchFeature.seeAllStandardPotionEffects)

--- Calculates the number of alchemy effects to show.
--- @param alchemy tes3alchemy
--- @return number
local function getAlchemyEffectsShown(alchemy)
	-- Check for MCP patch to show all standard effects.
	if (useMCPShowAllStandardPotionEffects and not alchemy.modified and not alchemy.blocked) then
		return 8
	end

	local alchemySkill = tes3.mobilePlayer.alchemy.current
	local fWortChanceValue = tes3.findGMST(tes3.gmst.fWortChanceValue).value
	return math.floor(alchemySkill / fWortChanceValue) * 2
end

--- Modifies a potion's tooltip.
--- @param tooltip tes3uiElement
--- @param alchemy tes3alchemy
local function replaceAlchemyTooltip(tooltip, alchemy)
	tryDestroyAllID(tooltip, "HelpMenu_effectBlock")

	-- Add space between title and effects.
	local title = tooltip:getContentElement().children[1]
	if title then
		title.borderBottom = 7
	end

	-- Value we'll use to see if the alchemy effect should be visible.
	local effectsShown = getAlchemyEffectsShown(alchemy)

	-- Loop through effects.
	for i = 1, #alchemy.effects do
		-- effects is a fixed size array, empty slots have the id -1.
		if alchemy.effects[i].id >= 0 then
			local block = tooltip:createBlock({ id = "HelpMenu_effectBlock" })
			block.minWidth = 1
			block.maxWidth = 640
			block.autoWidth = true
			block.autoHeight = true
			block.widthProportional = 1.0
			block.borderAllSides = 1
			block.borderLeft = 7
			block.borderRight = 7

			local icon = block:createImage({
				id = "HelpMenu_effectIcon",
				path = string.format("icons\\%s", alchemy.effects[i].object.icon),
			})
			icon.borderTop = 1
			icon.borderRight = 6
			local label = block:createLabel({
				id = "HelpMenu_effectLabel",
				text = string.format("%s", alchemy.effects[i]),
			})
			label.wrapText = false

			-- Hide the block if the PC's skill is too low.
			if i > effectsShown then
				block.visible = false
			end
		end
	end
end

local useMCPSoulgemValueRebalance = tes3.hasCodePatchFeature(tes3.codePatchFeature.soulgemValueRebalance)

--- Early pass at updating tooltip information.
--- @param e uiObjectTooltipEventData
local function extraTooltipEarly(e)
	-- I believe this is hardcoded in engine, so we'll just do this too.
	if not e.object.id:find("Gold_") and not e.object.isKey then
		tryHideID(e.tooltip, "HelpMenu_value")
		tryHideID(e.tooltip, "HelpMenu_weight")

		-- Add padding to the title.
		e.tooltip:getContentElement().children[1].borderAllSides = 3

		local objectValue = e.object.value

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
			replaceAlchemyTooltip(e.tooltip, e.object)

		-- Light duration
		elseif e.object.objectType == tes3.objectType.light then
			if e.object.time > 0 then
				local blockDurationBar = e.tooltip:createBlock()
				blockDurationBar.autoWidth = true
				blockDurationBar.autoHeight = true
				blockDurationBar.paddingAllSides = 4
				blockDurationBar.paddingLeft = 2
				blockDurationBar.paddingRight = 2
				blockDurationBar:createLabel({
					text = string.format("%s:", common.i18n("tooltip.lightDuration")),
				})

				local labelDurationBar = blockDurationBar:createFillBar({
					current = e.itemData and e.itemData.timeLeft or e.object.time,
					max = e.object.time,
				})
				labelDurationBar.borderLeft = 4
			end
		-- Soul gem capacity
		elseif e.object.isSoulGem then
			if (e.itemData and e.itemData.soul and e.itemData.soul.soul) then
				local soulValue = e.itemData.soul.soul
				labelFormatted(e.tooltip, string.format("%s: %u / %u", common.i18n("tooltip.soulCapacity"), soulValue, e.object.soulGemCapacity))

				-- Fixup item value based on MCP feature state.
				if (useMCPSoulgemValueRebalance) then
					objectValue = (soulValue ^ 3) / 10000 + soulValue * 2
				else
					objectValue = objectValue * soulValue
				end
			else
				labelFormatted(e.tooltip, string.format("%s: %u", common.i18n("tooltip.soulCapacity"), e.object.soulGemCapacity))
			end
		end

		-- Add the value and weight back in.
		if objectValue and e.object.weight then
			local container = e.tooltip:createBlock({ id = GUI_ID_TooltipIconBar })
			container.widthProportional = 1.0
			container.minHeight = 16
			container.autoHeight = true
			container.paddingAllSides = 2
			container.paddingTop = 4
			container.childAlignX = 1.0

			-- Value
			local valueBlock = container:createBlock({ id = GUI_ID_TooltipIconGoldBlock })
			valueBlock.autoWidth = true
			valueBlock.autoHeight = true
			valueBlock:createImage({ path = "icons/gold.dds" })
			local label = valueBlock:createLabel({ text = string.format("%u", objectValue) })
			label.borderLeft = 4

			-- Weight
			local weightBlock = container:createBlock({ id = GUI_ID_TooltipIconWeightBlock })
			weightBlock.autoWidth = true
			weightBlock.autoHeight = true
			weightBlock:createImage({ path = "icons/weight.dds" })
			weightBlock.borderLeft = 8
			label = weightBlock:createLabel({ text = string.format("%.2f", e.object.weight) })
			label.borderLeft = 4

			-- Value/Weight Ratio
			local ratioBlock
			if common.config.displayRatio and e.object.weight > 0 then
				local ratio = math.round(objectValue) / e.object.weight
				ratioBlock = container:createBlock({ id = GUI_ID_TooltipIconRatioBlock })
				ratioBlock.autoWidth = true
				ratioBlock.autoHeight = true
				ratioBlock:createImage({ path = "icons/ratio.dds" })
				ratioBlock.borderLeft = 8
				label = ratioBlock:createLabel({ text = string.format("%.2f", ratio) })
				label.borderLeft = 4
			end

			-- Update minimum width of the whole tooltip to make sure there's space for the value/weight/ratio.
			-- We have to updateLayout an extra time so we can get the correct element widths.
			e.tooltip:updateLayout()
			local blockPaddingWidth = 8
			local extraWidth = 16
			local valueBlockWidth = valueBlock.width
			local weightBlockWidth = weightBlock.width + blockPaddingWidth
			local widthNoRatio = valueBlockWidth + weightBlockWidth + extraWidth

			if common.config.displayRatio and e.object.weight > 0 then
				local ratioBlockWidth = ratioBlock.width + blockPaddingWidth
				local widthWithRatio = widthNoRatio + ratioBlockWidth
				e.tooltip:getContentElement().minWidth = widthWithRatio
			else
				e.tooltip:getContentElement().minWidth = widthNoRatio
			end
			e.tooltip:updateLayout()
		end

		-- Show a tooltip for stolen goods!
		local merchant = tes3ui.getServiceActor()
		if merchant ~= nil and e.object.stolenList ~= nil then
			for _, v in pairs(e.object.stolenList) do
				if merchant.object.name == v.name then
					e.tooltip:createDivider()
					local labelBlock = e.tooltip:createBlock({ id = GUI_ID_TooltipStolenLabel })
					labelBlock.minWidth = 1
					labelBlock.maxWidth = 210
					labelBlock.autoWidth = true
					labelBlock.autoHeight = true
					labelBlock.paddingAllSides = 1
					local label = labelBlock:createLabel({ text = common.i18n("inventory.stolenFromMerchant") })
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

--- Late pass at updating tooltip information.
--- @param e uiObjectTooltipEventData
local function extraTooltipLate(e)
	local element = e.tooltip:getContentElement()
	local children = element.children

	-- If neither divider nor icon bar isn't the last element, then something else was added, like flavor text.
	if children[#children].id ~= GUI_ID_TooltipExtraDivider and children[#children].id ~= GUI_ID_TooltipIconBar then
		local divide = element:findChild(GUI_ID_TooltipExtraDivider)
		if (divide) then
			divide.visible = true
		end
	end

	-- Now, we'll make sure our icon bar is in the position we want (currently the very bottom).
	-- TODO: add MCM option to set the position of the iconbar. Top, above enchants, above flavortext, bottom.
	for i = #children, 1, -1 do
		if children[i].id == GUI_ID_TooltipIconBar then
			element:reorderChildren(#children, i - 1, 1)
			break
		end
	end
end

-- Register our events, one early, and one late.
event.register("uiObjectTooltip", extraTooltipEarly, { priority = 100 })
event.register("uiObjectTooltip", extraTooltipLate, { priority = -100 })

--- Displays a stolen indicator when bartering with a merchant you've stolen from.
--- @param e itemTileUpdatedEventData
local function onItemTileUpdated(e)
	-- Show an indicator for stolen goods!
	local merchant = tes3ui.getServiceActor()
	if merchant ~= nil and e.item.stolenList ~= nil then
		for _, v in pairs(e.item.stolenList) do
			if merchant.reference.baseObject == v then
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
event.register("itemTileUpdated", onItemTileUpdated, { filter = "MenuInventory" })

--- Improve layout of spell tooltip.
--- @param e uiSpellTooltipEventData
local function extraSpellTooltipEarly(e)
	local GUI_ID_effect = tes3ui.registerID("effect")

	local main = e.tooltip:findChild("PartHelpMenu_main")
	if (not main) then
		return
	end

	local effectContainer = main:findChild(GUI_ID_effect)
	if (not effectContainer) then
		return
	end

	local helptext = main:findChild("helptext")
	if (helptext) then
		-- Spell title block.
		helptext.borderAllSides = 4
	end

	effectContainer.childAlignX = 0.5
	effectContainer.borderLeft = 6
	effectContainer.borderRight = 6

	for _, child in pairs(effectContainer.children) do
		if (child.id == GUI_ID_effect) then
			-- Fix magic effect alignment.
			local imgBlock = child.children[1]
			local textBlock = child.children[2]
			child.borderAllSides = 1
			imgBlock.borderRight = 4
			imgBlock.borderTop = 1
			textBlock.borderTop = nil
		else
			-- Probably spell school text. Not present for powers.
			child.borderAllSides = nil
			child.borderBottom = 9
		end
	end

	e.tooltip:updateLayout()
end

--- Show how long is left to recharge a power.
--- @param e uiSpellTooltipEventData
local function extraSpellTooltipLate(e)
	-- We have no way of knowing this is hovering over the player's power, but...
	-- where the hell else would you find powers?
	if (e.spell.castType == tes3.spellType.power) then
		local castTimestamp = tes3.mobilePlayer:getPowerUseTimestamp(e.spell)
		if (castTimestamp) then
			local timeToRecharge = math.abs(24 - (tes3.getSimulationTimestamp() - castTimestamp))
			local label = e.tooltip:createLabel({
				id = "UIEXP:PowerRechargeCooldown",
				text = common.i18n("tooltip.powerRechargeCooldown", { timeToRecharge }),
			})
			label.borderBottom = 4
			label.color = tes3ui.getPalette("disabled_color")
		end
	end
end
event.register("uiSpellTooltip", extraSpellTooltipEarly, { priority = 100 })
event.register("uiSpellTooltip", extraSpellTooltipLate, { priority = -100 })
