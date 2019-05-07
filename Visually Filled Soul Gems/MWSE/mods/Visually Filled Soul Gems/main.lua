
local effectEnchantment = nil

-- Callback for when a new scene node is created for a reference.
-- We'll use it add a visual effect to soul gems that are filled.
local function onReferenceSceneNodeCreated(e)
	local ref = e.reference
	if (not ref.object.isSoulGem) then
		return
	end

	-- No item data? No soul.
	local itemData = ref.attachments.variables
	if (itemData == nil) then
		return
	end

	-- Apply the enchant effect to the item.
	if (itemData.soul) then
		tes3.worldController:applyEnchantEffect(ref.sceneNode, effectEnchantment)
		ref.sceneNode:updateNodeEffects()
	end
end

local function onInitialized()
	-- Find an enchantment where the first effect is conjuration.
	effectEnchantment = tes3.getObject("bone guard_en")
	if (effectEnchantment) then
		event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated)
	else
		mwse.log("[Visually Filled Soul Gems] Could not find enchantment to base the effect off of. The mod will not function.")
	end
end
event.register("initialized", onInitialized)
