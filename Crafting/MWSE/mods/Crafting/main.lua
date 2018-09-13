local crafting = require("Crafting.module")

-- The path that data is stored in.
local dataDir = "Data Files/MWSE/mods/Crafting/data"

local function onInitialized(e)
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
end
event.register("initialized", onInitialized)

local function onKeyU(e)
	crafting.showCraftingMenu("armor")
end
event.register("keyDown", onKeyU, { filter = 22 })
