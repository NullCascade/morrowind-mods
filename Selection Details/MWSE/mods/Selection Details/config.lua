
--- @class SelectionDetailsConfig
--- @field requireControlKey boolean If true then the menu will only display if the player is holding the control key when selecting the object.
--- @field anchorToRightSide boolean If true then the menu will appear on the right side of the display instead of the left.

--- @type SelectionDetailsConfig
local config = mwse.loadConfig("Selection Details", {
	requireControlKey = true,
	anchorToRightSide = true,
})

return config
