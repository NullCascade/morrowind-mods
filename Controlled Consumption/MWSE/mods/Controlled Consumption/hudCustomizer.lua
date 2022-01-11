
local hudCustomizer = include("seph.hudCustomizer.interop")
if (not hudCustomizer) then
	return
end

-- Utility function to cut down on code duplication.
local function registrationWrapper(params)
	hudCustomizer:registerElement(params.id, params.name, params.defaults, params.options)
	if params.positionUpdated then
		event.register("seph.hudCustomizer:positionUpdated", params.positionUpdated, { filter = params.id })
	end
	if params.sizeUpdated then
		event.register("seph.hudCustomizer:sizeUpdated", params.sizeUpdated, { filter = params.id })
	end
	if params.visibilityUpdated then
		event.register("seph.hudCustomizer:visibilityUpdated", params.visibilityUpdated, { filter = params.id })
	end
	if params.alphaUpdated then
		event.register("seph.hudCustomizer:alphaUpdated", params.alphaUpdated, { filter = params.id })
	end
end

-- Registration must be done after initialization.
local function onInitialized()
	-- Allow the frame to be moved.
	registrationWrapper({
		name = "Controlled Consumption",
		id = "MenuMulti_ControlledConsumption_frame",
		defaults = {
			positionX = 0.135,
			positionY = 0.994,
			height = 32,
			width = 32,
			visible = false,
		},
		options = {
			position = true,
			size = true,
			visibility = false,
		},
		sizeUpdated = function(e)
			local frame = e.element

			-- The frame width is mostly ignored. But we resize our image to the values HUD Customizer puts there.
			local image = frame:findChild("MenuMulti_ControlledConsumption_image")
			image.width = frame.width
			image.height = frame.height
		end,
	})
end
event.register("initialized", onInitialized)