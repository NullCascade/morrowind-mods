
--[[
	Mod: Controlled Consumption
	Author: NullCascade

	This mod aims to balance the power of alchemy by implementing cooldowns or
	penalties for too much consumption. The mod is meant to be tailored to the
	preference of the user.

	The following configurations are available:
		* Vanilla NPC: A potion can only be consumed once every 5 seconds. This is
		  the same restriction NPCs have in vanilla.
		* Oblivion: Only 4 potions can be active at any one time.
]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180725) then
	mwse.log("[nc-consume] Build date of %s does not meet minimum build date of 20180725.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/consume/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/consume/", true)) then
		mwse.log("[nc-consume] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[nc-consume] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/consume' and restart Morrowind.")
		return
	end
end

-- Bring in our shared function/data module.
local shared = require("Controlled Consumption.shared")

-- Reference to the currently active module.
local currentModule = nil

-- Set of moduleName:table.
local modules = {}

-- Array of module names, relating to the modules keys.
local moduleNames = {}

-- The path that modules are stored in.
local moduleDir = "Data Files/MWSE/mods/Controlled Consumption/module"

-- File name for our config.
local configName = "Controlled Consumption"

-- Load the current config.
local config = mwse.loadConfig(configName) or {}

-- Minimum version support for modules, in case of breaking changes in modules.
local minimumModuleVersion = 1.2

-- Reference to the module configuration pane, so that modules can have access to it easily.
local moduleConfigPane = nil

-- Package to send to the mod config.
local modConfig = {}

-- Helper function to save the config file.
local function saveConfig()
	mwse.saveConfig(configName, config)
end

-- Loads a module from disk, does version checking, and sets up the state.
local function loadModule(file)
	-- Execute the file to get its module.
	local module = dofile(string.format("%s/%s.lua", moduleDir, file))

	-- Ensure that the minimum version requirements are met.
	local version = module.consumeVersion or 1.1
	if (version == nil or version < minimumModuleVersion) then
		mwse.log("[nc-consume] Module '%s' bypassed. Version %.1f does not meet minimum version %.1f", module.name, version, minimumModuleVersion)
		return
	end

	-- Report success, insert into module lists.
	mwse.log("[nc-consume] Found module: %s", module.name)
	table.insert(moduleNames, module.name)
	modules[module.name] = module
end

-- Sets the active module, invoking any needed callbacks.
local function setModule(name)
	-- Let the previous module know it is deactivated.
	if (currentModule) then
		local onSetInactive = currentModule.onSetInactive
		if (onSetInactive) then
			onSetInactive(config, moduleConfigPane)
		end
	end

	-- Hide the alchemy frame if it exists.
	if (shared.alchemyFrame) then
		shared.alchemyFrame.visible = false
	end

	-- Set the current module variable.
	currentModule = modules[name]
	if (currentModule == nil) then
		modConfig.hidden = true
		error("[nc-consume] Could not determine active module!")
	end
	config.currentModule = currentModule.name

	-- Let the module know it is activated.
	local onSetActive = currentModule.onSetActive
	if (onSetActive) then
		onSetActive(config, moduleConfigPane)
	end

	-- Update any config pane, if it's up.
	if (moduleConfigPane) then
		moduleConfigPane:destroyChildren()

		local onConfigCreate = currentModule.onConfigCreate
		if (onConfigCreate) then
			onConfigCreate(moduleConfigPane)
			moduleConfigPane.visible = true
		else
			moduleConfigPane.visible = false
		end
	end

	mwse.log("[nc-consume] Set module: %s", name)
end

-- Load the desired configuration module.
local function onInitialized(mod)
	if (mwse.buildDate == nil or mwse.buildDate < 20180712) then
		modConfig.hidden = true
		tes3.messageBox("Controlled Consumption requires a newer version of MWSE. Please run MWSE-Update.exe.", mwse.buildDate)
		return
	end

	-- Look through our module folder and load any modules.
	for file in lfs.dir(moduleDir) do
		local path = string.format("%s/%s", moduleDir, file)
		local fileAttributes = lfs.attributes(path)
		if (fileAttributes.mode == "file" and file:sub(-4, -1) == ".lua") then
			loadModule(file:match("(.+)%..+"))
		end
	end
	
	-- Try to use the selected module.
	local module = config.currentModule
	if ((module == nil or modules[module] == nil) and #moduleNames > 0) then
		module = modules["Vanilla NPC Style"] and "Vanilla NPC Style" or moduleNames[1]
	end
	setModule(module)
end
event.register("initialized", onInitialized)

-- Create the alchemy blocked icon.
local function logUI(e)
	local multiMenu = e.element

	-- Find the UI element that holds the sneak icon indicator.
	local bottomLeftBar = multiMenu:findChild(tes3ui.registerID("MenuMulti_sneak_icon")).parent

	-- Create an icon that matches the sneak icon's look.
	local alchemyFrame = bottomLeftBar:createThinBorder({})
	alchemyFrame.visible = false
	alchemyFrame.autoHeight = true
	alchemyFrame.autoWidth = true
	alchemyFrame.paddingAllSides = 2
	alchemyFrame.borderAllSides = 2
	alchemyFrame:createImage({ path = "icons/nc/potions_blocked.tga" })

	-- Expose the frame for other mods to muck with.
	shared.alchemyFrame = alchemyFrame
	alchemyFrame:register("destroy", function()
		shared.alchemyFrame = nil
	end)
end
event.register("uiCreated", logUI, { filter = "MenuMulti" })

-- 
-- Handle mod config menu.
-- 

local function modConfigChangeToNextModule(e)
	-- Don't allow module switching if potions are blocked.
	if (shared.alchemyFrame and shared.alchemyFrame.visible) then
		tes3.messageBox("Module switching is not allowed while potion drinking is blocked.")
		return
	end

	local index = table.find(moduleNames, currentModule.name) + 1
	if (index > #moduleNames) then
		index = 1
	end
	setModule(moduleNames[index])
	e.source.text = moduleNames[index]
end

-- Callback for when the mod config creates our UI. We specify this if we want to manually control
-- the look and functionality of our config, rather than leaving the logic entirely up to the mod
-- config system.
function modConfig.onCreate(container)
	-- Create the top bar that lets us change between configs.
	do
		-- The container is a scroll list. Create a row in that list that organizes elements horizontally.
		local horizontalBlock = container:createThinBorder({})
		horizontalBlock.flowDirection = "left_to_right"
		horizontalBlock.layoutWidthFraction = 1.0
		horizontalBlock.height = 32
		horizontalBlock.paddingAllSides = 6
	
		-- The text for the config option.
		local label = horizontalBlock:createLabel({ text = "Current consumption module:" })
		label.layoutOriginFractionX = 0.0
		label.layoutOriginFractionY = 0.5
		label.borderLeft = 8

		-- Button that toggles the config value.
		local button = horizontalBlock:createButton({ text = currentModule.name })
		button.layoutOriginFractionX = 1.0
		button.layoutOriginFractionY = 0.5
		button:register("mouseClick", modConfigChangeToNextModule)
	end

	-- Create the reusable pane that modules will put their config in.
	moduleConfigPane = container:createThinBorder({})
	moduleConfigPane.flowDirection = "top_to_bottom"
	moduleConfigPane.borderTop = 6
	moduleConfigPane.paddingAllSides = 6
	moduleConfigPane.layoutWidthFraction = 1.0
	moduleConfigPane.layoutHeightFraction = 1.0
	moduleConfigPane:register("destroy", function()
		moduleConfigPane = nil
	end)

	-- Fire off the current module's event to create its UI.
	local moduleEvent = currentModule.onConfigCreate
	if (moduleEvent) then
		moduleEvent(moduleConfigPane)
		moduleConfigPane.visible = true
	else
		moduleConfigPane.visible = false
	end
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function modConfig.onClose(container)
	local moduleEvent = currentModule.onConfigClose
	if (moduleEvent) then
		moduleEvent(config, moduleConfigPane)
	end

	saveConfig()
end

-- When the mod config menu is ready to start accepting registrations, register this mod.
local function registerModConfig()
	mwse.registerModConfig("Controlled Consumption", modConfig)
end
event.register("modConfigReady", registerModConfig)
