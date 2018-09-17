local crafting = require("Crafting.module")

-- The path that data is stored in.
local dataDir = "Data Files/MWSE/mods/Crafting/data"

local function onInitialized(e)
	local memoryBefore = collectgarbage("count")

	crafting.preInitialized()

	-- Look through our data folder and load any packages.
	for file in lfs.dir(dataDir) do
		local path = string.format("%s/%s", dataDir, file)
		local fileAttributes = lfs.attributes(path)
		if (fileAttributes.mode == "file" and file:sub(-4, -1) == ".lua") then
			dofile(path)
		end
	end

	crafting.postInitialized()

	mwse.log("Crafting system initialized. Recipe memory impact: %.2f KB", (collectgarbage("count") - memoryBefore))
end
event.register("initialized", onInitialized)

local function onKeyU(e)
	tes3.messageBox({
		message = "Which crafting menu?",
		buttons = {
			"Armor",
			"Smelting",
			"Weapons",
		},
		callback = function(e)
			timer.delayOneFrame(function()
				if (e.button == 0) then
					crafting.showCraftingMenu({ handler = "armor" })
				elseif (e.button == 1) then
					crafting.showCraftingMenu({ handler = "smelting" })
				elseif (e.button == 2) then
					crafting.showCraftingMenu({ handler = "weapon" })
				end
			end)
		end
	})
end
event.register("keyDown", onKeyU, { filter = 22 })
