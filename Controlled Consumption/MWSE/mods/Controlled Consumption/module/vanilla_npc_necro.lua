local this = {}

local shared = require("Controlled Consumption.shared")

-- Name to identify this module.
this.name = "Vanilla NPC Style (Necro Edit)"
this.consumeVersion = 1.2

-- Callback for when the config is created.
function this.onConfigCreate(container)

    -- Required for text to initially wrap.
    container:getTopLevelParent():updateLayout()

    -- No real config. Just a description.
    local description = container:createLabel({
        text =
            "This module follows the same rules as vanilla NPCs follow. Only one potion or ingredient can be consumed at a time, and five seconds must pass before another one can be consumed.\n" ..
            "\n" ..
            "This edited version of the module uses a simulate timer rather than a game timer, to ensure a consistent timer duration even when the timescale changes."
    })
    description.layoutWidthFraction = 1.0
    description.wrapText = true
end

-- We use a simple timer to keep track of consumption state.
local consumeCooldownTimer = nil

-- Cooldown time.
local cooldownTime = 5

-- When the timer completes, we hide the frame alchemy icon and unset the variable.
local function onTimerComplete()
    consumeCooldownTimer = nil

    if shared.alchemyFrame then
        shared.alchemyFrame.visible = false
    end
end

-- Our main logic for seeing if a potion can be consumed or not.
function this.onEquip(e)

    -- Make some basic checks (player equipping, it's a potion, etc).
    if not shared.basicPotionChecks(e) then
        return
    end

    -- Do we already have a potion active?
    if consumeCooldownTimer and consumeCooldownTimer.state == timer.active then
        tes3.messageBox("You must wait another %d seconds before consuming another potion or ingredient.", consumeCooldownTimer.timeLeft)
        return false
    end

    -- Start our 5-second cooldown and show the alchemy blocked frame.
    consumeCooldownTimer = timer.start({
        duration = cooldownTime,
        callback = onTimerComplete
    })

    if shared.alchemyFrame then
        shared.alchemyFrame.visible = true
    end
end

-- Set any remaining time so that it persists through saves.
function this.onSave()
    local data = shared.getPersistentData()

    if consumeCooldownTimer and consumeCooldownTimer.state == timer.active then
        data.nc.consume.npcTimeLeft = consumeCooldownTimer.timeLeft
    else
        data.nc.consume.npcTimeLeft = nil
    end
end

-- Loaded event. Resume any consumption restrictions.
function this.onLoaded()
    local data = shared.getPersistentData()
    local timeLeft = data.nc.consume.npcTimeLeft

    if timeLeft then

        -- We drank recently. Start a timer with the remaining time left and show the icon.
        consumeCooldownTimer = timer.start({
            duration = timeLeft,
            callback = onTimerComplete
        })

        if shared.alchemyFrame then
            shared.alchemyFrame.visible = true
        end
    else

        -- Make sure the icon is hidden if we're loading a save where we didn't just drink a potion.
        if shared.alchemyFrame then
            shared.alchemyFrame.visible = false
        end
    end
end

-- Callback for when this module is set as the active one.
function this.onSetActive()

    -- Delete any save data.
    local data = shared.getPersistentData()

    if data then
        data.nc.consume.npcTimeLeft = nil
    end

    -- Also unset any data in our module.
    if consumeCooldownTimer then
        consumeCooldownTimer:cancel()
    end

    consumeCooldownTimer = nil

    -- Setup the events we care about.
    event.register("equip", this.onEquip)
    event.register("save", this.onSave)
    event.register("loaded", this.onLoaded)
end

-- Callback for when this module is turned off.
function this.onSetInactive()

    -- Delete any save data.
    local data = shared.getPersistentData()

    if data then
        data.nc.consume.npcTimeLeft = nil
    end

    -- Also unset any data in our module.
    if consumeCooldownTimer then
        consumeCooldownTimer:cancel()
    end

    consumeCooldownTimer = nil

    -- Remove the events we cared about.
    event.unregister("equip", this.onEquip)
    event.unregister("save", this.onSave)
    event.unregister("loaded", this.onLoaded)
end

return this