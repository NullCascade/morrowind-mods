
local GUI_ID_HelpMenu = tes3ui.registerID("HelpMenu")
local GUI_ID_MenuStat_scroll_pane = tes3ui.registerID("MenuStat_scroll_pane")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")
local GUI_Palette_Negative = tes3ui.getPalette("negative_color")
local GUI_Palette_Positive = tes3ui.getPalette("positive_color")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Stats Menu: Display active modifiers.
----------------------------------------------------------------------------------------------------

local attributeModifyingEffects = { tes3.effect.drainAttribute, tes3.effect.damageAttribute, tes3.effect.fortifyAttribute }
local skillModifyingEffects = { tes3.effect.drainSkill, tes3.effect.damageSkill, tes3.effect.fortifySkill }

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
		adjustmentsBlock:createLabel({ text = string.format("Raw value: %d", rawValue) }).borderBottom = 6
	end
	adjustmentsBlock:createLabel({ text = string.format("Base value: %d", baseValue) }).borderBottom = 6

	-- Display any modifiers.
	adjustmentsBlock:createLabel({ text = "Modifiers:" })
	local modifierCount = 0
	local activeEffect = tes3.mobilePlayer.activeMagicEffects
	local magicEffects = tes3.dataHandler.nonDynamicData.magicEffects
	for i = 1, tes3.mobilePlayer.activeMagicEffectCount do
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

			local icon = block:createImage({ path = string.format("icons/%s", effect.icon) })
			icon.borderRight = 6

			local magicInstance = activeEffect.instance
			local sourceLabel = block:createLabel({ text = (magicInstance.item or magicInstance.source).name or "Unknown" })
			if (activeEffect.effectId == fortifyEffect) then
				local magnitudeLabel = block:createLabel({ text = string.format("+%d", activeEffect.magnitude) })
				magnitudeLabel.color = GUI_Palette_Positive
				magnitudeLabel.borderLeft = 2
				magnitudeLabel.absolutePosAlignX = 1.0
			else
				local magnitudeLabel = block:createLabel({ text = string.format("-%d", activeEffect.magnitude) })
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
			helpText = adjustmentsBlock:createLabel({ text = "Raw value does not involve any effects." })
			helpText.color = GUI_Palette_Disabled
			helpText.borderTop = 6
		end

		helpText = adjustmentsBlock:createLabel({ text = "Base value takes into account abilities, and affects faction requirements." })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end

	if ( modifierCount < 1 ) then
		adjustmentsBlock.visible = false
	end
end

local function onMenuStatAttributeTooltip(e)
	OnMenuStatTooltip(e, attributeModifyingEffects, "MenuStat_attribute_strength", tes3.effect.fortifyAttribute, "attributes")
end

local function onMenuStatSkillTooltip(e)
	OnMenuStatTooltip(e, skillModifyingEffects, "MenuStat_message", tes3.effect.fortifySkill, "skills")
end

local function onMenuStatActivated(e)
	local idParts = { "agility", "endurance", "intellegence", "luck", "personality", "speed", "strength", "willpower" }
	for _, idPart in pairs(idParts) do
		local MenuStat_attribute_layout = e.element:findChild(tes3ui.registerID(string.format("MenuStat_attribute_layout_%s", idPart)))
		MenuStat_attribute_layout:register("help", onMenuStatAttributeTooltip)

		-- Prevent children from using their own events.
		local children = MenuStat_attribute_layout.children
		for _, child in pairs(children) do
			child.consumeMouseEvents = false
		end
	end
end
event.register("uiActivated", onMenuStatActivated, { filter = "MenuStat" } )

local idFilters = { tes3ui.registerID("MenuStat_misc_layout"), tes3ui.registerID("MenuStat_minor_layout"), tes3ui.registerID("MenuStat_major_layout") }

local function onStatsMenuRefreshed(e)
	local scrollPaneChildren = e.element:findChild(GUI_ID_MenuStat_scroll_pane):findChild(GUI_ID_PartScrollPane_pane).children
	for _, element in pairs(scrollPaneChildren) do
		if (table.find(idFilters, element.id)) then
			element:register("help", onMenuStatSkillTooltip)

			local children = element.children
			for _, child in pairs(children) do
				child.consumeMouseEvents = false
			end
		end
	end
end
event.register("uiRefreshed", onStatsMenuRefreshed, { filter = "MenuStat_scroll_pane" })
