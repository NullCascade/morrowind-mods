
--- @class SelectionDetailsConfig
--- @field requireControlKey boolean If true then the menu will only display if the player is holding the control key when selecting the object.

--- @type SelectionDetailsConfig
local config = mwse.loadConfig("Selection Details", {
	requireControlKey = true,
})

return config
