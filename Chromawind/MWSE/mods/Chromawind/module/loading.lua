local interop = require("Chromawind.interop")

local module = {}

module.name = "loading"
module.gameInitialized = false
module.secondPass = true

local loadingFillColor = interop.razerSDK.color(0, 0.8, 0.8)
local defaultColor = interop.razerSDK.color(0.1, 0.1, 0.1)

function module.clearKeyboardData()
	local data = module.keyboardData
	for r = 1, 6 do
		local row = data[r]
		for c = 1, 22 do
			row[c] = 0
		end
	end
end

local lastColumn = 0
local lastUpdateTime = 0

-- Initialize keyboard data.
module.keyboardData = table.new(6, 0)
for r = 1, 6 do
	module.keyboardData[r] = table.new(22, 0)
end
module.clearKeyboardData()

function module.onStart()
	lastColumn = 0
	module.secondPass = not module.secondPass
end

function module.onStop()

end

local function onMenuLoadingUpdate(e)
	-- Throttle updating to 60 FPS.
	if (os.clock() - lastUpdateTime < (1/60)) then
		return
	end

	local MenuLoading = e.source

	local MenuLoading_fill = MenuLoading:findChild("MenuLoading_fill").widget
	local column = math.ceil(22 * MenuLoading_fill.current / 100)
	if (column == lastColumn) then
		return
	end

	local color = loadingFillColor
	if (module.secondPass) then
		color = defaultColor
	end

	if (column > lastColumn) then
		local data = module.keyboardData
		for c = math.max(1, lastColumn), column do
			for r = 1, 6 do
				data[r][c] = color
			end
		end

		lastColumn = column
		lastUpdateTime = os.clock()

		interop.razerInstance:createKeyboardEffect("CHROMA_CUSTOM", module.keyboardData)
	end
end

---@param e uiActivatedEventData
local function onLoadingMenuActivated(e)
	if (not e.newlyCreated or module.gameInitialized) then
		return
	end

	if (tes3.player) then
		return
	end

	e.element:registerAfter("update", onMenuLoadingUpdate)

	-- Reset module when the loading menu is cleared.
	e.element:registerBefore("destroy", function()
		if (interop.getCurrentModule() == module) then
			interop.setCurrentModule()
		end
	end)

	interop.setCurrentModule(module)
end
event.register("uiActivated", onLoadingMenuActivated, { filter = "MenuLoading" })

local function onInitialized()
	module.gameInitialized = true
end
event.register("initialized", onInitialized)

return module