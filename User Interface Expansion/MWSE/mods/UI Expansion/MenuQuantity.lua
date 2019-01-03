local common = require("UI Expansion.common")

local function menuQuantity(e)
    -- Enable keyboard support for the scroll bar.
    local scrollBar = e.element:findChild(tes3ui.registerID("MenuQuantity_scrollbar"))
    local submitButton = e.element:findChild(tes3ui.registerID("MenuQuantity_buttonok"))
    common.bindScrollBarToKeyboard({
        element = scrollBar,
        onSubmit = function()
            submitButton:triggerEvent("mouseClick")
        end
    })
end
event.register("uiActivated", menuQuantity, { filter = "MenuQuantity"})