local crafting = require("Crafting.module")

crafting.registerHandler({ id = "armor" })

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

if (false) then
    -- Example recipe.
    crafting.registerRecipe({
        -- Categorization.
        handler = "armor", -- Provide a table to register to multiple handlers.
    
        -- The skill that will get leveled.
        skill = tes3.skill.armorer, -- Provide a string to use Merlord's Skill Module.
    
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
            { id = "key", value = 3 }, -- tes3.player.data[key] >= value
        },
        globalReqs = {
            { id = "GameHour", value = 12, text = "Only valid between midnight and noon." }, -- tes3.getGlobal("key") >= value
        },
        journalReqs = {
            { id = "key", value = 3 }, -- tes3.getJournalIndex("key") >= value
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