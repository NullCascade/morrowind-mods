
-- Make sure we have the latest MWSE version.
if (mwse.buildDate < 20210708) then
	event.register("loaded", function()
		tes3.messageBox("[Consistent Enchanting] This mod requires a newer version of MWSE. Run MWSE-Update.exe.")
	end)
	return
end

local config = require("Consistent Enchanting.config")

local cachedItemData = nil
local cachedLuaData = nil
local cachedLuaTempData = nil
local cachedScriptVariables = nil

local propertiesToCopy = { "condition" }

local function onMenuEnchantActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local menuEnchantment = e.element
	menuEnchantment:findChild("MenuEnchantment_Buybutton"):registerBefore("mouseClick", function()
		-- Reset data.
		cachedItemData = nil
		cachedLuaData = nil
		cachedLuaTempData = nil
		cachedScriptVariables = nil

		 -- Get existing object/itemData. These are not typos... :todd:
		local item = menuEnchantment:findChild("MenuEnchantment_Item"):getPropertyObject("MenuEnchantment_SoulGem")
		local itemData = menuEnchantment:findChild("MenuEnchantment_Item"):getPropertyObject("MenuEnchantment_Item", "tes3itemData")
		if (not itemData) then
			return
		end

		-- Store what we care about.
		cachedItemData = {}
		for _, k in ipairs(propertiesToCopy) do
			if (config.copy[k]) then
				cachedItemData[k] = itemData[k]
			end
		end
		if (table.empty(cachedItemData)) then
			cachedItemData = nil
		end

		-- Store any lua data tables so they don't get GC'd.
		if (config.copy.luaData) then
			cachedLuaData = itemData.data
		end
		if (config.copy.luaTempData) then
			cachedLuaTempData = itemData.tempData
		end

		-- Store script variable values.
		if (config.copy.script and config.copy.scriptData) then
			if (itemData.script and itemData.scriptVariables) then
				cachedScriptVariables = {}
				for k, v in pairs(itemData.context:getVariableData()) do
					cachedScriptVariables[k] = v.value
				end
			end
		end
	end)
end
event.register("uiActivated", onMenuEnchantActivated, { filter = "MenuEnchantment" })

local function onEnchantItem(e)
	-- Was there a script? If so copy it over.
	if (config.copy.script and e.baseObject.script) then
		e.object.script = e.baseObject.script
	end

	local itemData = e.object.script and tes3.player.object.inventory:findItemStack(e.object).variables[1] or tes3.addItemData({ to = tes3.player, item = e.object })

	-- Copy over basic properties.
	if (cachedItemData) then
		for k, v in pairs(cachedItemData) do
			itemData[k] = v
		end
	end

	-- Copy lua data over.
	if (cachedLuaData) then
		itemData.data = cachedLuaData
	end
	if (cachedLuaTempData) then
		itemData.tempData = cachedLuaTempData
	end

	-- Script data to copy over?
	if (itemData.script and itemData.scriptVariables and cachedScriptVariables) then
		local context = itemData.context
		for k, v in pairs(cachedScriptVariables) do
			context[k] = v
		end
	end

	-- Store base item so other mods can reference it?
	if (config.storeBaseObject) then
		itemData.data.ncceEnchantedFrom = e.baseObject.id:lower()
	end

	-- Store soul so other mods can reference it?
	if (config.storeSoulUsed) then
		itemData.data.ncceEnchantedSoul = e.soul.id:lower()
	end
end
event.register("enchantedItemCreated", onEnchantItem)

-- Handle MCM.
dofile("Consistent Enchanting.mcm")
