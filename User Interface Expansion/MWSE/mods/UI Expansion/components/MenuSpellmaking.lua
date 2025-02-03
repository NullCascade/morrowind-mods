
--- Create our changes for MenuServiceSpells.
---@param e uiActivatedEventData
local function onUIActivated(e)
	-- We only care if this is the node time it was activated.
	if (not e.newlyCreated) then
		return
	end

	local effectsScroll = e.element:findChild("MenuSpellmaking_EffectsScroll")
	local effectsScrollContent = effectsScroll.widget.contentPane
	local effectProperty = tes3ui.registerID("MenuSpellmaking_Effect")
	local MenuSpellmaking_EffectIcon = tes3ui.registerID("MenuSpellmaking_EffectIcon")
	local MenuSpellmaking_EffectName = tes3ui.registerID("MenuSpellmaking_EffectName")
	local MenuSpellmaking_Effect_Click = 0x621990
	local MenuSpellmaking_Effect_Help = 0x622E70

	-- Store and clear existing effects.
	local knownEffects = {}
	for _, child in ipairs(effectsScrollContent.children) do
		table.insert(knownEffects, child:getPropertyObject(effectProperty, "tes3magicEffect"))
	end
	effectsScrollContent:destroyChildren()
	table.sort(knownEffects, function(a, b) return a.name < b.name end)

	-- Create our new effects list.
	effectsScrollContent.flowDirection = "top_to_bottom"
	for _, effect in ipairs(knownEffects) do
		local effectBlock = effectsScrollContent:createBlock()
		effectBlock.flowDirection = "left_to_right"
		effectBlock.autoWidth = true
		effectBlock.autoHeight = true
		effectBlock.childAlignY = 0.5
		effectBlock.borderBottom = 2
		effectBlock:setPropertyObject(effectProperty, effect)
		effectBlock:register("mouseClick", MenuSpellmaking_Effect_Click)
		effectBlock:register("help", MenuSpellmaking_Effect_Help)

		local icon = effectBlock:createImage({ id = MenuSpellmaking_EffectIcon, path = string.format("icons\\%s", effect.icon) })
		icon:setPropertyObject(effectProperty, effect)

		local name = effectBlock:createTextSelect({ id = MenuSpellmaking_EffectName, text = effect.name })
		name.borderLeft = 2
		name:setPropertyObject(effectProperty, effect)
	end

	e.element:updateLayout()
end
event.register("uiActivated", onUIActivated, { filter = "MenuSpellmaking" })
