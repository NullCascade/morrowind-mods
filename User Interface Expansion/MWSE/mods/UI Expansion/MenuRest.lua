local common = require("UI Expansion.common")

local weekDays = {
    "Sundas",
    "Morndas",
    "Tirdas",
    "Middas",
    "Turdas",
    "Fredas",
    "Loredas"
}

local function menuRestWait(e)
    if (not common.config.displayWeekday) then
        return
    end
    -- +3 offset, since the 16th of Last Seed (starting day) should be Thurdas.
    local day = weekDays[(tes3.worldController.daysPassed.value + 3) % 7 + 1]
    e.element.children[2].children[1].text =  day .. ", " .. e.element.children[2].children[1].text
end
event.register("uiActivated", menuRestWait, { filter = "MenuRestWait"})