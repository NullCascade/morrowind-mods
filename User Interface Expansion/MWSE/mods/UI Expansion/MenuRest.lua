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

local digit

local function getKeyInput(e)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuRestWait"))
    local scroll = menu:findChild(tes3ui.registerID("MenuRestWait_scrollbar"))
    local wait = menu:findChild(tes3ui.registerID("MenuRestWait_wait_button"))
    local rest = menu:findChild(tes3ui.registerID("MenuRestWait_rest_button"))

    -- Enter pressed- start resting.
    if (e.keyCode == 28) then
        if (rest ~= nil) then
            rest:triggerEvent("mouseClick")
        else
            wait:triggerEvent("mouseClick")
        end
    end

    -- Not a number.
    if (e.keyCode < 2 or e.keyCode > 11) then
        return
    end

    local num = e.keyCode - 1
    if (num == 10) then
        num = 0
    end

    if (digit < 168)then
        digit = digit * 10 + num
    else
        digit = num
    end

    scroll.widget.current = math.min(math.max(1, digit - 1), common.config.maxWait)
    scroll:triggerEvent("PartScrollBar_changed")
end

local function menuRestWait(e)
    digit = 0
    event.register("keyDown", getKeyInput)
    event.register("menuExit", function ()
        event.unregister("keyDown", getKeyInput)
    end, { doOnce = true})

    if (not common.config.displayWeekday) then
        return
    end
    -- +3 offset, since the 16th of Last Seed (starting day) should be Thurdas.
    local day = weekDays[(tes3.worldController.daysPassed.value + 3) % 7 + 1]
    e.element.children[2].children[1].text =  day .. ", " .. e.element.children[2].children[1].text
end
event.register("uiActivated", menuRestWait, { filter = "MenuRestWait"})