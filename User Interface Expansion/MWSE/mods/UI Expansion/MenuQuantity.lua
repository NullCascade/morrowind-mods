local common = require("UI Expansion.common")

local function menuQuantity(e)
    local scroll = e.element:findChild(tes3ui.registerID("MenuQuantity_scrollbar"))
    local submit = e.element:findChild(tes3ui.registerID("MenuQuantity_buttonok"))
    common.getKeyInput(scroll.widget.max + 1,
    function(num)
        scroll.widget.current = math.max(num - 1, 0)
        scroll:triggerEvent("PartScrollBar_changed")
    end,
    function()
        submit:triggerEvent("mouseClick")
    end)
end
event.register("uiActivated", menuQuantity, { filter = "MenuQuantity"})