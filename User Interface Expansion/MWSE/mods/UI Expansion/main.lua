local common = require("UI Expansion.lib.common")
local config = require("UI Expansion.config")

-- Make sure we have the latest MWSE version.
if (mwse.buildDate < 20231218) then
	event.register("loaded", function()
		tes3.messageBox(common.i18n("core.updateRequired"))
	end)
	return
end

-- Set up MCM.
dofile("UI Expansion.mcm")

-- Run our modules.
local function onInitialized()
	if (config.components.barter) then
		dofile("UI Expansion.components.MenuBarter")
	end
	if (config.components.console) then
		dofile("UI Expansion.components.MenuConsole")
	end
	if (config.components.contents) then
		dofile("UI Expansion.components.MenuContents")
	end
	if (config.components.dialog) then
		dofile("UI Expansion.components.MenuDialog")
	end
	if (config.components.inventory) then
		dofile("UI Expansion.components.MenuInventory")
	end
	if (config.components.inventorySelect) then
		dofile("UI Expansion.components.MenuInventorySelect")
	end
	if (config.components.magic) then
		dofile("UI Expansion.components.MenuMagic")
	end
	if (config.components.magicSelect) then
		dofile("UI Expansion.components.MenuMagicSelect")
	end
	if (config.components.map) then
		dofile("UI Expansion.components.MenuMap")
	end
	if (config.components.mapPlugin) then
		dofile("UI Expansion.components.MenuMapPlugin")
	end
	if (config.components.name) then
		dofile("UI Expansion.components.MenuName")
	end
	if (config.components.options) then
		dofile("UI Expansion.components.MenuOptions")
	end
	if (config.components.quantity) then
		dofile("UI Expansion.components.MenuQuantity")
	end
	if (config.components.rest) then
		dofile("UI Expansion.components.MenuRest")
	end
	if (config.components.saveLoad) then
		dofile("UI Expansion.components.MenuSaveLoad")
	end
	if (config.components.serviceSpells) then
		dofile("UI Expansion.components.MenuServiceSpells")
	end
	if (config.components.spellmaking) then
		dofile("UI Expansion.components.MenuSpellmaking")
	end
	if (config.components.stat) then
		dofile("UI Expansion.components.MenuStat")
	end
	if (config.components.tooltip) then
		dofile("UI Expansion.components.Tooltip")
	end
	if (config.components.training) then
		dofile("UI Expansion.components.MenuServiceTraining")
	end
	if (config.components.textInput) then
		dofile("UI Expansion.components.textInput")
	end
end
event.register(tes3.event.initialized, onInitialized)

-- Hook map changes.
local externMapPlugin = include("uiexp_map_extension")
if (externMapPlugin and config.components.mapPlugin) then
	-- Clear deprecated config data.
	config.mapConfig.autoExpand = nil

	-- Call into plugin.
	externMapPlugin.hookMapOverrides(config.mapConfig)
end
