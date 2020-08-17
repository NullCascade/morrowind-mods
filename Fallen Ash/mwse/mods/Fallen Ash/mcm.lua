local config = require("Fallen Ash.config")

local template = mwse.mcm.createTemplate{name="Fallen Ash"}
template:saveOnClose("Fallen Ash", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferences"}
preferences.sidebar:createInfo{
    text = "Fallen Ash Version 1.0\n\nCreated by Greatness7 and NullCascade.\n\nMouse over a feature for more info."
}

-- Feature Toggles
preferences:createOnOffButton{
    label = "Ignore Actors",
    description = "This feature controls whether or not the mod will ignore actors. (e.g. NPCs and Creatures)",
    variable = mwse.mcm:createTableVariable{
        id = "ignoreActors",
        table = config,
    },
}

preferences:createOnOffButton{
    label = "Ignore Items",
    description = "This feature controls whether or not the mod will ignore items. (e.g. Objects that can be looted)",
    variable = mwse.mcm:createTableVariable{
        id = "ignoreItems",
        table = config,
    },
}

preferences:createTextField{
    label = "Minimum Object Size",
    description = "The minimum size for objects that will be affected by the mod.",
    variable = mwse.mcm:createTableVariable{
        numbersOnly = true,
        id = "minimumSize",
        table = config,
    },
}

-- Blacklist Page
template:createExclusionsPage{
    label = "Blacklist",
    description = "This page allows you to specify any individual objects that you do not want to be affected by the ash decals.",
    leftListLabel = "Blacklist",
    rightListLabel = "Objects",
    variable = mwse.mcm:createTableVariable{
        id = "blacklist",
        table = config,
    },
    filters = {
        {
            label = "Activator",
            type = "Object",
            objectType = tes3.objectType.activator,
        },
        {
            label = "Alchemy",
            type = "Object",
            objectType = tes3.objectType.alchemy,
        },
        {
            label = "Ammunition",
            type = "Object",
            objectType = tes3.objectType.ammunition,
        },
        {
            label = "Apparatus",
            type = "Object",
            objectType = tes3.objectType.apparatus,
        },
        {
            label = "Armor",
            type = "Object",
            objectType = tes3.objectType.armor,
        },
        {
            label = "Book",
            type = "Object",
            objectType = tes3.objectType.book,
        },
        {
            label = "Clothing",
            type = "Object",
            objectType = tes3.objectType.clothing,
        },
        {
            label = "Container",
            type = "Object",
            objectType = tes3.objectType.container,
        },
        {
            label = "Door",
            type = "Object",
            objectType = tes3.objectType.door,
        },
        {
            label = "Ingredient",
            type = "Object",
            objectType = tes3.objectType.ingredient,
        },
        {
            label = "Light",
            type = "Object",
            objectType = tes3.objectType.light,
        },
        {
            label = "Lockpick",
            type = "Object",
            objectType = tes3.objectType.lockpick,
        },
        {
            label = "MiscItem",
            type = "Object",
            objectType = tes3.objectType.miscItem,
        },
        {
            label = "Probe",
            type = "Object",
            objectType = tes3.objectType.probe,
        },
        {
            label = "RepairItem",
            type = "Object",
            objectType = tes3.objectType.repairItem,
        },
        {
            label = "Static",
            type = "Object",
            objectType = tes3.objectType.static,
        },
        {
            label = "Weapon",
            type = "Object",
            objectType = tes3.objectType.weapon,
        },
    },
}
