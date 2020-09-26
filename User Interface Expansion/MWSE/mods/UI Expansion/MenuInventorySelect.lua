
local GUI_ID_MenuAlchemy = tes3ui.registerID("MenuAlchemy")
local GUI_ID_MenuInventorySelect = tes3ui.registerID("MenuInventorySelect")
local GUI_ID_MenuInventorySelect_item_brick = tes3ui.registerID("MenuInventorySelect_item_brick")
local GUI_ID_MenuInventorySelect_prompt = tes3ui.registerID("MenuInventorySelect_prompt")
local GUI_ID_MenuInventorySelect_scrollpane = tes3ui.registerID("MenuInventorySelect_scrollpane")

local common = require("UI Expansion.common")

----------------------------------------------------------------------------------------------------
-- Generic filter cases
----------------------------------------------------------------------------------------------------

local function updateInventorySelectTiles()
	tes3ui.updateInventorySelectTiles()
	event.trigger("UIEXP:updatedInventorySelectTiles")
end

local genericFilter = common.createFilterInterface({
	filterName = "inventorySelect",
	createSearchBar = true,
	createIcons = true,
	createButtons = false,
	useIcons = true,
	useSearch = common.config.useSearch,
	onFilterChanged = updateInventorySelectTiles,
})

common.createStandardInventoryFilters(genericFilter)

----------------------------------------------------------------------------------------------------
-- Generic filter case w/o icons.
----------------------------------------------------------------------------------------------------

local genericFilterNoIcons = common.createFilterInterface({
	filterName = "inventorySelectNoIcons",
	createSearchBar = true,
	createIcons = false,
	createButtons = false,
	useIcons = false,
	useSearch = common.config.useSearch,
	onFilterChanged = updateInventorySelectTiles,
})

----------------------------------------------------------------------------------------------------
-- Custom filter for handling ingredients.
----------------------------------------------------------------------------------------------------

local function getShownIngredientEffectCount()
	return math.clamp(math.floor(tes3.mobilePlayer.alchemy.current / tes3.findGMST(tes3.gmst.fWortChanceValue).value), 0, 4)
end

local function updateIngredientList()
	local MenuAlchemy = tes3ui.findMenu(GUI_ID_MenuAlchemy)
	local MenuInventorySelect = tes3ui.findMenu(GUI_ID_MenuInventorySelect)
	if (MenuAlchemy and MenuInventorySelect) then
		-- Values we'll use to see if the alchemy effect should be visible.
		local maxShownEffect = getShownIngredientEffectCount()

		-- If we don't know any effects, no features apply so save ourself the trouble.
		if (maxShownEffect == 0) then
			return
		end
		
		-- Build a list of effects that work.
		local effects = {}
		for _, v in ipairs({ "one", "two", "three", "four" }) do
			local block = MenuAlchemy:findChild(tes3ui.registerID("MenuAlchemy_ingredient_".. v))
			local ingredient = block:getPropertyObject("MenuAlchemy_object")
			if (ingredient) then
				for i = 1, maxShownEffect do
					local effectId = ingredient.effects[i]
					if (effectId >= 0) then
						local r = effects[ingredient.effects[i]] or {}
						r.attribute = r.attribute or {}
						r.skill = r.skill or {}
						
						r.attribute[common.getIngredientEffectAttributeId(ingredient, i)] = true
						r.skill[common.getIngredientEffectSkillId(ingredient, i)] = true
						effects[ingredient.effects[i]] = r
					end
				end
			end
		end

		-- If we haven't found any effects then bail.
		if (table.empty(effects)) then
			return
		end

		-- Loop through blocks...
		for _, child in ipairs(MenuInventorySelect:findChild(GUI_ID_MenuInventorySelect_scrollpane).widget.contentPane.children) do
			local ingredient = child:getPropertyObject("MenuInventorySelect_object")

			-- Look for a match for the current ingredients.
			local match = false
			for i = 1, maxShownEffect do
				local submatch = effects[ingredient.effects[i]]
				if (submatch and submatch.attribute[common.getIngredientEffectAttributeId(ingredient, i)] and submatch.skill[common.getIngredientEffectSkillId(ingredient, i)]) then
					match = true
					break
				end
			end

			-- If we didn't get a match, use the disabled color.
			if (not match) then
				local text = child:findChild(GUI_ID_MenuInventorySelect_item_brick)
				text.color = tes3ui.getPalette("disabled_color")
			end
		end
	end
end

local function updateIngredientSelectTiles()
	tes3ui.updateInventorySelectTiles()
	updateIngredientList()
	event.trigger("UIEXP:updatedInventorySelectTiles")
end

local ingredientFilterNoIcons = common.createFilterInterface({
	filterName = "inventorySelectIngredientsNoIcons",
	createSearchBar = true,
	createIcons = false,
	createButtons = false,
	useIcons = false,
	useSearch = common.config.useSearch,
	onFilterChanged = updateIngredientSelectTiles,
})


----------------------------------------------------------------------------------------------------
-- Custom filter for handling soulgems.
----------------------------------------------------------------------------------------------------

local function updateSoulGemList()
	local MenuInventorySelect = tes3ui.findMenu(GUI_ID_MenuInventorySelect)
	if (MenuInventorySelect) then
		local pane = MenuInventorySelect:findChild(GUI_ID_MenuInventorySelect_scrollpane).widget.contentPane

		-- Sort elements.
		pane:sortChildren(function(a, b)
			local itemDataA = a:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")
			local itemDataB = b:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")
			return itemDataA.soul.soul < itemDataB.soul.soul
		end)

		-- Flush out the elements.
		for _, child in ipairs(pane.children) do
			-- General fixes.
			child.childAlignY = 0.5

			-- Get the associated itemData.
			local soulGem = child:getPropertyObject("MenuInventorySelect_object")
			local itemData = child:getPropertyObject("MenuInventorySelect_extra", "tes3itemData")

			-- Hide the original text.
			local label = child:findChild(GUI_ID_MenuInventorySelect_item_brick)
			label.visible = false

			-- Create a new block with the soulgem name and soul name.
			local newBlock = child:createBlock({ id = "UIEXP:InventorySelect:NamesBlock" })
			newBlock.flowDirection = "top_to_bottom"
			newBlock.heightProportional = 1.0
			newBlock.autoWidth = true
			newBlock.childAlignY = 0.5
			newBlock.borderLeft = 2
			newBlock.consumeMouseEvents = false

			-- Show the name.
			local name = newBlock:createLabel({ id = "UIEXP:InventorySelect:SoulGemName" })
			name.text = soulGem.name
			name.consumeMouseEvents = false

			-- Show the soul contents.
			local soulName = newBlock:createLabel({ id = "UIEXP:InventorySelect:SoulValue" })
			soulName.text = string.format("%s (%d/%d)", itemData.soul.name, itemData.soul.soul, soulGem.soulGemCapacity)
			soulName.color = tes3ui.getPalette("disabled_color")
			soulName.consumeMouseEvents = false

			child:updateLayout()
		end
		
	end
end

local function updateSoulGemSelectTiles()
	tes3ui.updateInventorySelectTiles()
	updateSoulGemList()
	event.trigger("UIEXP:updatedInventorySelectTiles")
end

local soulGemFilterNoIcons = common.createFilterInterface({
	filterName = "inventorySelectSoulGemsNoIcons",
	createSearchBar = true,
	createIcons = false,
	createButtons = false,
	useIcons = false,
	useSearch = common.config.useSearch,
	onFilterChanged = updateSoulGemSelectTiles,
})

----------------------------------------------------------------------------------------------------
-- Inventory Select: Searching and advanced filtering.
----------------------------------------------------------------------------------------------------

local currentFilter = nil

local function onFilterInventorySelect(e)
	if (currentFilter) then
		e.text = e.item.name
		if (not currentFilter:triggerFilter(e)) then
			e.filter = false
		end
	end
end
event.register("filterInventorySelect", onFilterInventorySelect )

local inventorySelectTypeFilterMap = {
	["alembic"] = genericFilterNoIcons,
	["calcinator"] = genericFilterNoIcons,
	["ingredient"] = ingredientFilterNoIcons,
	["mortar"] = genericFilterNoIcons,
	["retort"] = genericFilterNoIcons,
	["soulGemFilled"] = soulGemFilterNoIcons,
}
common.inventorySelectTypeFilterMap = inventorySelectTypeFilterMap

local function onMenuInventorySelectActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- Create a home for our filter buttons, and reposition it.
	local inventorySelectPane = e.element:findChild(GUI_ID_MenuInventorySelect_prompt).parent
	local filterBlock = inventorySelectPane:createBlock({ id = "UIEXP:InventorySelect:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4
	inventorySelectPane:reorderChildren(1, -1, 1)

	-- Don't carry the filter over between sessions.
	filterBlock:register("destroy", function() currentFilter = nil end)

	-- Change filtering options based on what menu we're specifically looking at.
	local inventorySelectType = tes3ui.getInventorySelectType()
	currentFilter = inventorySelectTypeFilterMap[inventorySelectType] or genericFilter
	currentFilter:createElements(filterBlock)
	currentFilter:focusSearchBar()
end
event.register("uiActivated", onMenuInventorySelectActivated, { filter = "MenuInventorySelect" } )
