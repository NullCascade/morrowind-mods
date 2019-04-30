--[[

	Allows using a simple key to toggle the HUD.

--]]

local GUIID_MenuMulti = nil

local config = mwse.loadConfig("HUD Hider")
config = config or {}
config.toggleKey = config.toggleKey or {
	keyCode = tes3.scanCode.closeSquareBracket,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = true
}

local function keybindTest(b, e)
	return (b.keyCode == e.keyCode) and (b.isShiftDown == e.isShiftDown) and (b.isAltDown == e.isAltDown) and (b.isControlDown == e.isControlDown)
end

local function onKeyDown(e)
	if (not keybindTest(config.toggleKey, e)) then
		return
	end

	-- All the code needed to actually toggle the HUD.
	local menuMulti = tes3ui.findMenu(GUIID_MenuMulti)
	menuMulti.visible = not menuMulti.visible
end
event.register("keyDown", onKeyDown)

local function onInitialized()
	GUIID_MenuMulti = tes3ui.registerID("MenuMulti")
end
event.register("initialized", onInitialized, { doOnce = true })

local function registerModConfig()
	local easyMCM = include("easyMCM.EasyMCM")
	if (easyMCM == nil) then
		return
	end

	local template = easyMCM.createTemplate("HUD Hider")
	template:saveOnClose("HUD Hider", config)

	local page = template:createPage()
	page:createKeyBinder{
		label = "Assign Keybind",
		allowCombinations = true,
		variable = easyMCM.createTableVariable{
			id = "toggleKey",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.closeSquareBracket,
				isShiftDown = false,
				isAltDown = false,
				isControlDown = true,
			}
		}
	}

	easyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)
