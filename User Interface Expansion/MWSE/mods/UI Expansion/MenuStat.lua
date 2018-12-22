local GUI_ID_HelpMenu = tes3ui.registerID("HelpMenu")
local GUI_ID_MenuStat_faction_layout = tes3ui.registerID("MenuStat_faction_layout")
local GUI_ID_MenuStat_scroll_pane = tes3ui.registerID("MenuStat_scroll_pane")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")
local GUI_Palette_Negative = tes3ui.getPalette("negative_color")
local GUI_Palette_Positive = tes3ui.getPalette("positive_color")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Stats Menu: Display active modifiers.
----------------------------------------------------------------------------------------------------

local attributeModifyingEffects = {
	tes3.effect.drainAttribute,
	tes3.effect.damageAttribute,
	tes3.effect.fortifyAttribute
}
local skillModifyingEffects = {tes3.effect.drainSkill, tes3.effect.damageSkill, tes3.effect.fortifySkill}

local function OnMenuStatTooltip(e, effectFilter, idProperty, fortifyEffect, statsArray)
	-- Allow the tooltip to be made per usual.
	e.source:forwardEvent(e)

	-- Get the associated attribute.
	local attribute = e.source:getPropertyInt(idProperty)

	-- Create a new tooltip block.
	local tooltip = tes3ui.findHelpLayerMenu(GUI_ID_HelpMenu)
	local adjustmentsBlock = tooltip:createBlock({})
	adjustmentsBlock.flowDirection = "top_to_bottom"
	adjustmentsBlock.autoHeight = true
	adjustmentsBlock.autoWidth = true
	adjustmentsBlock.widthProportional = 1.0
	adjustmentsBlock.borderLeft = 6
	adjustmentsBlock.borderRight = 6
	adjustmentsBlock.borderBottom = 6

	-- Show raw/base values.
	local rawValue = tes3.player.object[statsArray][attribute + 1]
	local baseValue = tes3.mobilePlayer[statsArray][attribute + 1].base
	if (rawValue ~= baseValue) then
		adjustmentsBlock:createLabel({text = string.format(common.dictionary.statRawValue, rawValue)}).borderBottom = 6
	end
	adjustmentsBlock:createLabel({text = string.format(common.dictionary.statBaseValue, baseValue)}).borderBottom = 6

	-- Display any modifiers.
	adjustmentsBlock:createLabel({text = common.dictionary.statModifiers})
	local modifierCount = 0
	local activeEffect = tes3.mobilePlayer.activeMagicEffects
	local magicEffects = tes3.dataHandler.nonDynamicData.magicEffects
	for _ = 1, tes3.mobilePlayer.activeMagicEffectCount do
		activeEffect = activeEffect.next

		if (activeEffect.attributeId == attribute and table.find(effectFilter, activeEffect.effectId)) then
			local block = adjustmentsBlock:createBlock({})
			block.flowDirection = "left_to_right"
			block.widthProportional = 1.0
			block.autoWidth = true
			block.autoHeight = true
			block.borderLeft = 10
			block.borderRight = 10
			block.borderTop = 4

			local effect = magicEffects[activeEffect.effectId + 1]

			local icon = block:createImage({path = string.format("icons/%s", effect.icon)})
			icon.borderRight = 6

			local magicInstance = activeEffect.instance
			block:createLabel({text = (magicInstance.item or magicInstance.source).name or common.dictionary.unknown})
			if (activeEffect.effectId == fortifyEffect) then
				local magnitudeLabel = block:createLabel({text = string.format("+%d", activeEffect.magnitude)})
				magnitudeLabel.color = GUI_Palette_Positive
				magnitudeLabel.borderLeft = 2
				magnitudeLabel.absolutePosAlignX = 1.0
			else
				local magnitudeLabel = block:createLabel({text = string.format("-%d", activeEffect.magnitude)})
				magnitudeLabel.color = GUI_Palette_Negative
				magnitudeLabel.borderLeft = 2
				magnitudeLabel.absolutePosAlignX = 1.0
			end

			modifierCount = modifierCount + 1
		end
	end

	if (common.config.showHelpText) then
		local helpText

		if (rawValue ~= baseValue) then
			helpText = adjustmentsBlock:createLabel({text = common.dictionary.statHelpRawValue})
			helpText.color = GUI_Palette_Disabled
			helpText.borderTop = 6
		end

		helpText = adjustmentsBlock:createLabel({text = common.dictionary.statHelpBaseValue})
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end

	if (modifierCount < 1) then
		adjustmentsBlock.visible = false
	end
end

local function onMenuStatAttributeTooltip(e)
	OnMenuStatTooltip(
		e,
		attributeModifyingEffects,
		"MenuStat_attribute_strength",
		tes3.effect.fortifyAttribute,
		"attributes"
	)
end

local function onMenuStatSkillTooltip(e)
	OnMenuStatTooltip(e, skillModifyingEffects, "MenuStat_message", tes3.effect.fortifySkill, "skills")
end

local function onMenuStatFactionTooltip(e)
	-- Allow the tooltip to be made per usual.
	e.source:forwardEvent(e)

	-- Get the associated faction.
	local faction = e.source:getPropertyObject("MenuStat_message")

	-- Create a new tooltip block.
	local tooltip = tes3ui.findHelpLayerMenu(GUI_ID_HelpMenu)
	local adjustmentsBlock = tooltip:createBlock({})
	adjustmentsBlock.flowDirection = "top_to_bottom"
	adjustmentsBlock.autoHeight = true
	adjustmentsBlock.autoWidth = true
	adjustmentsBlock.widthProportional = 1.0
	adjustmentsBlock.borderLeft = 6
	adjustmentsBlock.borderRight = 6
	adjustmentsBlock.borderBottom = 6

	-- Show current player reputation.
	local reputation = faction.playerReputation
	adjustmentsBlock:createLabel({text = string.format(common.dictionary.statFactionReputation, reputation)})

	-- If the player isn't of max rank, show the next needed reputation.
	if (faction.playerRank < 9) then
		local nextRankRequirements = faction.ranks[faction.playerRank + 2]
		local reputationReqLabel = adjustmentsBlock:createLabel({text = string.format(common.dictionary.statFactionReputationRequirement, nextRankRequirements.reputation)})
		reputationReqLabel.borderTop = 6
	end
end

local function onMenuStatActivated(e)
	local idParts = {"agility", "endurance", "intellegence", "luck", "personality", "speed", "strength", "willpower"}
	for _, idPart in pairs(idParts) do
		local MenuStat_attribute_layout =
			e.element:findChild(tes3ui.registerID(string.format("MenuStat_attribute_layout_%s", idPart)))
		MenuStat_attribute_layout:register("help", onMenuStatAttributeTooltip)

		-- Prevent children from using their own events.
		local children = MenuStat_attribute_layout.children
		for _, child in pairs(children) do
			child.consumeMouseEvents = false
		end
	end
end
event.register("uiActivated", onMenuStatActivated, {filter = "MenuStat"})

local attributeTooltipElements = {
	tes3ui.registerID("MenuStat_misc_layout"),
	tes3ui.registerID("MenuStat_minor_layout"),
	tes3ui.registerID("MenuStat_major_layout")
}

local function onStatsMenuRefreshed(e)
	local scrollPaneChildren = e.element:findChild(GUI_ID_PartScrollPane_pane).children
	for _, element in pairs(scrollPaneChildren) do
		if (table.find(attributeTooltipElements, element.id)) then
			-- Show enhanced statistics tooltips on attributes/skills.
			element:register("help", onMenuStatSkillTooltip)

			local children = element.children
			for _, child in pairs(children) do
				child.consumeMouseEvents = false
			end
		elseif (element.id == GUI_ID_MenuStat_faction_layout) then
			-- Show increased faction information.
			element:register("help", onMenuStatFactionTooltip)

			local children = element.children
			for _, child in pairs(children) do
				child.consumeMouseEvents = false
			end
		end
	end
end
event.register("uiRefreshed", onStatsMenuRefreshed, {filter = "MenuStat_scroll_pane"})
