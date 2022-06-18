local GUI_ID_HelpMenu = tes3ui.registerID("HelpMenu")
local GUI_ID_MenuStat_faction_layout = tes3ui.registerID("MenuStat_faction_layout")
local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")
local GUI_Palette_Negative = tes3ui.getPalette("negative_color")
local GUI_Palette_Positive = tes3ui.getPalette("positive_color")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Stats Menu: Display active modifiers.
----------------------------------------------------------------------------------------------------

--- Adds more information to tooltips for attributes/skills.
--- @param source tes3uiElement
--- @param effectFilter string
--- @param idProperty string
--- @param fortifyEffect number
--- @param statsArray string
local function OnMenuStatTooltip(source, effectFilter, idProperty, fortifyEffect, statsArray)
	-- Get the associated attribute.
	local attribute = source:getPropertyInt(idProperty)

	-- Create a new tooltip block.
	local tooltip = tes3ui.findHelpLayerMenu(GUI_ID_HelpMenu)
	if not tooltip then
		return
	end

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
		adjustmentsBlock:createLabel({ text = common.i18n("stat.rawValue", { rawValue }) }).borderBottom = 6
	end
	adjustmentsBlock:createLabel({ text = common.i18n("stat.baseValue", { baseValue }) }).borderBottom = 6

	-- Display any modifiers.
	adjustmentsBlock:createLabel({ text = common.i18n("stat.modifiers") })
	local foundModifiers = false
	local activeEffects = tes3.mobilePlayer:getActiveMagicEffects() --- @type tes3activeMagicEffect[]
	for _, activeEffect in ipairs(activeEffects) do
		local effect = tes3.getMagicEffect(activeEffect.effectId)
		if (effect[effectFilter] and activeEffect.attributeId == attribute) then
			local block = adjustmentsBlock:createBlock()
			block.flowDirection = "left_to_right"
			block.widthProportional = 1.0
			block.autoWidth = true
			block.autoHeight = true
			block.borderLeft = 10
			block.borderRight = 10
			block.borderTop = 4

			local icon = block:createImage({ path = string.format("icons/%s", effect.icon) })
			icon.borderRight = 6

			local magicInstance = activeEffect.instance
			block:createLabel({ text = (magicInstance.item or magicInstance.source).name })
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

			foundModifiers = true
		end
	end

	if (common.config.showHelpText) then
		local helpText

		if (rawValue ~= baseValue) then
			helpText = adjustmentsBlock:createLabel({ text = common.i18n("stat.helpRawValue") })
			helpText.color = GUI_Palette_Disabled
			helpText.borderTop = 6
		end

		helpText = adjustmentsBlock:createLabel({ text = common.i18n("stat.helpBaseValue") })
		helpText.color = GUI_Palette_Disabled
		helpText.borderTop = 6
	end

	if (not foundModifiers) then
		adjustmentsBlock.visible = false
	end
end

--- Update attribute tooltips.
--- @param e tes3uiEventData
local function onMenuStatAttributeTooltip(e)
	OnMenuStatTooltip(e.source, "targetsAttributes", "MenuStat_attribute_strength", tes3.effect.fortifyAttribute, "attributes")
end

--- Update skill tooltips.
--- @param e tes3uiEventData
local function onMenuStatSkillTooltip(e)
	OnMenuStatTooltip(e.source, "targetsSkills", "MenuStat_message", tes3.effect.fortifySkill, "skills")
end

--- Update faction tooltips.
--- @param e tes3uiEventData
local function onMenuStatFactionTooltip(e)
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
	adjustmentsBlock:createLabel({ text = common.i18n("stat.factionReputation", { reputation }) })

	-- If the player isn't of max rank, show the next needed reputation.
	if (faction.playerRank < 9) then
		local nextRankRequirements = faction.ranks[faction.playerRank + 2]
		local reputationReqLabel = adjustmentsBlock:createLabel({
			text = common.i18n("stat.factionReputationRequirement", { nextRankRequirements.reputation }),
		})
		reputationReqLabel.borderTop = 6
	end
end

--- Add image to the class tooltip.
--- @param e tes3uiEventData
local function onMenuStatClassTooltip(e)
	local tooltip = tes3ui.findHelpLayerMenu(GUI_ID_HelpMenu)
	if not tooltip then
		return
	end

	-- We only care if the class has a custom image.
	local class = tes3.player.baseObject.class
	local classImage = class.image
	if (classImage) then
		local description = tooltip:findChild("description")

		local imageContainer = description.parent:createThinBorder({
			id = "image_container",
		})
		imageContainer.autoWidth = true
		imageContainer.autoHeight = true
		imageContainer.paddingAllSides = 2
		imageContainer:createImage({
			id = "image",
			path = classImage,
		})

		-- Move it before the description.
		description.parent:reorderChildren(description, imageContainer, 1)
	end

	tooltip:updateLayout()
end

--- Create our changes for MenuStat.
--- @param e uiActivatedEventData
local function onMenuStatActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Improve class tooltips.
	local classLayout = e.element:findChild("MenuStat_class_layout")
	if (classLayout) then
		local label = classLayout:findChild("MenuStat_class_name")
		label:registerAfter("help", onMenuStatClassTooltip)
		local class = classLayout:findChild("MenuStat_class")
		class:registerAfter("help", onMenuStatClassTooltip)
	end

	-- Add tooltips to attributes.
	local idParts = { "agility", "endurance", "intellegence", "luck", "personality", "speed", "strength", "willpower" }
	for _, idPart in pairs(idParts) do
		local MenuStat_attribute_layout = e.element:findChild(string.format("MenuStat_attribute_layout_%s", idPart))
		MenuStat_attribute_layout:registerAfter("help", onMenuStatAttributeTooltip)

		-- Prevent children from using their own events.
		local children = MenuStat_attribute_layout.children
		for _, child in pairs(children) do
			child.consumeMouseEvents = false
		end
	end
end
event.register("uiActivated", onMenuStatActivated, { filter = "MenuStat" })

local attributeTooltipElements = {
	[tes3ui.registerID("MenuStat_misc_layout")] = true,
	[tes3ui.registerID("MenuStat_minor_layout")] = true,
	[tes3ui.registerID("MenuStat_major_layout")] = true,
}

--- Called when the stats menu is refreshed.
--- @param e uiRefreshedEventData
local function onStatsMenuRefreshed(e)
	local scrollPaneChildren = e.element:findChild(GUI_ID_PartScrollPane_pane).children
	for _, element in pairs(scrollPaneChildren) do
		if (attributeTooltipElements[element.id]) then
			-- Show enhanced statistics tooltips on attributes/skills.
			element:registerAfter("help", onMenuStatSkillTooltip)

			local children = element.children
			for _, child in pairs(children) do
				child.consumeMouseEvents = false
			end
		elseif (element.id == GUI_ID_MenuStat_faction_layout) then
			-- Show increased faction information.
			element:registerAfter("help", onMenuStatFactionTooltip)

			local children = element.children
			for _, child in pairs(children) do
				child.consumeMouseEvents = false
			end
		end
	end
end
event.register("uiRefreshed", onStatsMenuRefreshed, { filter = "MenuStat_scroll_pane" })
