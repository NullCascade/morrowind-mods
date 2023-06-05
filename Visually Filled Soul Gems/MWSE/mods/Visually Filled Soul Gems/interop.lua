local interop = {}

local config = require("Visually Filled Soul Gems.config")
local log = require("Visually Filled Soul Gems.log")

--- @type tes3enchantment?
interop.enchantEffectBase = nil

--- Gets the soul on a given reference.
--- @param reference tes3reference
--- @return tes3actor?
function interop.getSoul(reference)
	if (not reference.object.isSoulGem) then
		return nil
	end

	local itemData = reference.itemData
	if (itemData == nil) then
		return nil
	end

	return itemData.soul
end

--- Sets a soul gem reference's active effect.
--- @param reference tes3reference The reference to set the effect on.
--- @param active boolean? If true, the effect will be added. If `nil`, it it will try to determine if the reference contains a soul.
function interop.setSoulEffectActive(reference, active)
	if (reference.sceneNode == nil) then
		return
	end

	if (active == nil) then
		active = interop.getSoul(reference) ~= nil
	end

	-- See if there is a node to turn on.
	local activeEffectNode = reference.sceneNode:getObjectByName("SoulActive")
	if (activeEffectNode) then
		activeEffectNode.appCulled = not active
	end

	-- Apply our plastic wrap effect if enabled.
	if (active and config.useEnchantEffect and interop.enchantEffectBase) then
		tes3.worldController:applyEnchantEffect(reference.sceneNode, interop.enchantEffectBase)
		reference.sceneNode:updateEffects()
	end
end

--- Sets the enchantment to use with a given ID.
--- @param id string
function interop.setEnchantmentEffect(id)
	interop.enchantEffectBase = nil

	local enchantment = tes3.getObject(id) --[[@as tes3enchantment?]]
	if (enchantment == nil) then
		log:warn("No enchantment could be found with ID '%s'.", config.enchantmentId)
		return
	end

	if (enchantment.objectType ~= tes3.objectType.enchantment) then
		log:warn("The object with ID '%s' is not an enchantment.", config.enchantmentId)
		return
	end

	interop.enchantEffectBase = enchantment
	log:debug("Enchantment effect changed to '%s'", id)

	-- Refresh any active soul gems.
	interop.refreshActiveSoulGems()
end

--- Removes the soul effect from a reference.
--- @param reference tes3reference
function interop.clearSoulEffect(reference)
	if (reference.sceneNode == nil) then
		return
	end

	local activeEffectNode = reference.sceneNode:getObjectByName("SoulActive")
	if (activeEffectNode) then
		activeEffectNode.appCulled = true
	end

	-- Try to remove the enchanted effect.
	reference.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
	reference.sceneNode:updateEffects()

	log:trace("Cleared soul effect from reference: %s", reference)
end

--- Purges all effects from soul gems then recalculates them.
function interop.refreshActiveSoulGems()
	for _, cell in ipairs(tes3.getActiveCells()) do
		for reference in cell:iterateReferences(tes3.objectType.miscItem) do
			if (reference.object.isSoulGem) then
				interop.clearSoulEffect(reference)
				interop.setSoulEffectActive(reference)
			end
		end
	end
end

return interop
