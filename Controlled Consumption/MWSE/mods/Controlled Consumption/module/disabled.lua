local this = {}

-- Name to identify this module.
this.name = "Disabled"
this.consumeVersion = 1.2

-- Callback for when the config is created.
function this.onConfigCreate(container)
	-- Required for text to initially wrap.
	container:getTopLevelParent():updateLayout()

	-- No real config. Just a description.
	local description = container:createLabel({ text = "No consumption module will be used." })
	description.layoutWidthFraction = 1.0
	description.wrapText = true
end

return this