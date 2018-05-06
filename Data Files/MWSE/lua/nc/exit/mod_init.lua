
--[[
	Mod Initialization: Expeditious Exit
	Author: NullCascade

	This mod is for people who seem to have issues crashing or losing mouse control
	on exit. By hijacking the exit buttons, this mod will force the game to exit.

	Doing it this way isn't wonderful! In a perfect world we wouldn't do it this
	way, but if it helps you, great.
]]--

local function uiPreEvent(e)
    if (e.property == tes3.uiProperty.mouseClick and e.block.name == "MenuOptions_Exit_container") then
        print("[nc-exit] Forcing exit!")
        os.exit()
    end
end
event.register("uiPreEvent", uiPreEvent)
