local common = require("UI Expansion.common")


local function checkReverseShiftInAlch(elem)
    local alchMenu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
    if(alchMenu ~= nil) then
        if (common.config.alchemyDefaultQuantity) then
            elem:triggerEvent("mouseClick")
        end
    end
end


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
    checkReverseShiftInAlch(submitButton);
end
event.register("uiActivated", menuQuantity, { filter = "MenuQuantity"})