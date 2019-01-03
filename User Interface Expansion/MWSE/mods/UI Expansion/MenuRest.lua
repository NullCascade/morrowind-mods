local common = require("UI Expansion.common")

local function menuRestWait(e)
    local scroll = e.element:findChild(tes3ui.registerID("MenuRestWait_scrollbar"))
    scroll.widget.max = common.config.maxWait * 24 - 1
    scroll.widget.jump = 4 -- More useful default value.
    scroll:updateLayout()

    -- Enable keyboard input on the scroll bar.
    local wait = e.element:findChild(tes3ui.registerID("MenuRestWait_wait_button"))
    local rest = e.element:findChild(tes3ui.registerID("MenuRestWait_rest_button"))
    common.bindScrollBarToKeyboard({
        element = scroll,
        onSubmit = function()
            if (rest ~= nil) then
                rest:triggerEvent("mouseClick")
            else
                wait:triggerEvent("mouseClick")
            end
        end
    })

    if (not common.config.displayWeekday) then
        return
    end
    -- +3 offset, since the 16th of Last Seed (starting day) should be Thurdas.
    local day = common.dictionary.weekDays[(tes3.worldController.daysPassed.value + 3) % 7 + 1]
    e.element.children[2].children[1].text =  day .. ", " .. e.element.children[2].children[1].text
end
event.register("uiActivated", menuRestWait, { filter = "MenuRestWait"})