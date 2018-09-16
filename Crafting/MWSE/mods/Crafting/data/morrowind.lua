local crafting = require("Crafting.module")

-- Material IDs to be used, depending on if TR is installed or not.
local idOreGold = tes3.getObject("tr_ing_gold") and "tr_ing_gold" or "craft_or_gold"
local idOreIron = tes3.getObject("tr_ing_iron") and "tr_ing_iron" or "craft_or_iron"

-- Crafting handlers.
crafting.registerHandler({ id = "armor", title = "Armor Smithing", successSound = "repair", failureSound = "repair fail" })
crafting.registerHandler({ id = "smelting", title = "Smeltery", successSound = "repair", failureSound = "repair fail" })
crafting.registerHandler({ id = "weapon", title = "Weapon Smithing", successSound = "repair", failureSound = "repair fail" })

-- Ingots and other crafting materials.
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_corundum", itemReqs = { "craft_or_corundum" } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_dwarven", itemReqs = { { id = "ingred_scrap_metal_01", count = 3 } } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_ebony", itemReqs = { { id = "ingred_raw_ebony_01", count = 2 } } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_gold", itemReqs = { idOreGold } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_iron", itemReqs = { idOreIron } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_malachite", itemReqs = { { id = "ingred_raw_glass_01", count = 3 } } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_silver", itemReqs = { "craft_or_silver" } })
crafting.registerRecipe({ handler = "smelting", skill = tes3.skill.armorer, difficulty = -50, result = "craft_in_steel", itemReqs = { "craft_or_corundum", idOreIron } })

-- Light armor.
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_boots", itemReqs = { { id = "ingred_raw_glass_01", count = 5 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_bracer_left", itemReqs = { { id = "ingred_raw_glass_01", count = 2 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_bracer_right", itemReqs = { { id = "ingred_raw_glass_01", count = 2 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_cuirass", itemReqs = { { id = "ingred_raw_glass_01", count = 10 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_greaves", itemReqs = { { id = "ingred_raw_glass_01", count = 7 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_helm", itemReqs = { { id = "ingred_raw_glass_01", count = 4 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_pauldron_left", itemReqs = { { id = "ingred_raw_glass_01", count = 4 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_pauldron_right", itemReqs = { { id = "ingred_raw_glass_01", count = 4 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_shield", itemReqs = { { id = "ingred_raw_glass_01", count = 8 } } })
crafting.registerRecipe({ handler = "armor", skill = tes3.skill.armorer, result = "glass_towershield", itemReqs = { { id = "ingred_raw_glass_01", count = 13 } } })

if (true) then
	-- Example recipe.
	crafting.registerRecipe({
		-- Categorization.
		handler = "armor", -- Provide a table to register to multiple handlers.

		-- Optional description.
		description = "These light and elegant weapons of Elven manufacture feature extravagant use of rare metals and cutting edges made from rare crystalline materials. Duellists and assassins appreciate the delicate balance and sinister sharpness of glass weapons.",
	
		-- The skill that will get leveled.
		skill = tes3.skill.illusion, -- Provide a string to use Merlord's Skill Module.
	
		-- What gets crafted.
		result = { id = "glass throwing knife", count = 10 }, -- Provide just a string to assume count = 1
	
		-- Requirements:
		itemReqs = {
			{ id = "ingred_raw_glass_01", count = 2, consume = false }, -- Provide just a string to assume count = 1 and consume = true
		},
		skillReqs = {
			{ id = tes3.skill.armorer, value = 20 }, -- Minimum skill values to even try to craft.
		},
		dataReqs = {
			-- { id = "key", min = 3, text = "Must have killed a golden saint." }, -- tes3.player.data[key] >= value
		},
		globalReqs = {
			{ id = "GameHour", min = 6, max = 18, text = "Only valid during the day." }, -- tes3.getGlobal("key") >= value
		},
		-- journalReqs = {
		-- 	{ id = "key", min = 3 }, -- tes3.getJournalIndex("key") >= value
		-- },
		customReqs = {
			{
				text = "Must be in an exterior.",
				callback = function(package)
					return (tes3.getPlayerCell().isInterior == false)
				end
			},
		},
	
		-- Other configuration.
		successSound = "", -- Overrides the handler's sound used when successfully crafting an item.
		failureSound = "", -- Overrides the handler's sound used when failing to craft an item.
	
		-- Events:
		onShowList = nil, -- Provide a function to manipulate the list block.
		onCraftSuccess = nil, -- Provide a function to know when the crafting is complete.
		onCraftFailure = nil, -- Provide a function to know when the crafting is failed.
		onCraftAttempt = nil, -- Provide a function to override logic for crafting attempt.
	})
end
