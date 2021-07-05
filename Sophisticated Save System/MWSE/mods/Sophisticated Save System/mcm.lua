local this = {}

local config = require("Sophisticated Save System.config")
local interop = require("Sophisticated Save System.interop")

local template = mwse.mcm.createTemplate("Sophisticated Save System")
template:saveOnClose("Sophisticated Save System", config)

local page = template:createPage()

page:createYesNoButton({
    label = "Make Quick Load use the latest save of any type?",
    description = "Normally the \"Quick Load\" feature will only load the latest save made using \"Quick Save\". This feature makes loading a quick save instead load the newest save of any type.",
    variable = mwse.mcm.createTableVariable({
        id = "loadLatestSave",
        table = config,
    }),
})

page:createTextField({
    label = "Number of autosaves to keep:",
    description = "The maximum number of autosaves to keep. The oldest autosaves are deleted to make room for new ones.",
    variable = mwse.mcm.createTableVariable({
        id = "maxSaveCount",
        table = config,
        numbersOnly = true,
    }),
})

page:createTextField({
    label = "Minimum time between autosaves:",
    description = "When an autosave has been queued, it won't be made until at least this much time (in minutes) has passed.",
    variable = mwse.mcm.createTableVariable({
        id = "minimumTimeBetweenAutoSaves",
        table = config,
        numbersOnly = true,
    }),
})

page:createYesNoButton({
    label = "Create autosaves on a timer?",
    description = "An autosave is only queued if something significant has happened since the last autosave.\n\nWith this feature, enough time passing will queue a save.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnTimer",
        table = config,
    }),
})

page:createTextField({
    label = "Autosave timer duration:",
    description = "When creating autosaves on a timer, wait this long.",
    variable = mwse.mcm.createTableVariable({
        id = "timeBetweenAutoSaves",
        table = config,
        numbersOnly = true,
    }),
})

page:createYesNoButton({
    label = "Create autosaves when combat starts?",
    description = "An autosave is only queued if something significant has happened since the last autosave.\n\nWith this feature, starting combat will queue a save.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnCombatStart",
        table = config,
    }),
})

page:createYesNoButton({
    label = "Create autosaves when combat ends?",
    description = "An autosave is only queued if something significant has happened since the last autosave.\n\nWith this feature, ending combat will queue a save.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnCombatEnd",
        table = config,
    }),
})

page:createYesNoButton({
    label = "Create autosaves after changing cells?",
    description = "An autosave is only queued if something significant has happened since the last autosave.\n\nWith this feature, changing cells will queue a save.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnCellChange",
        table = config,
    }),
})

mwse.mcm.register(template)
