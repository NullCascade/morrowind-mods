local interop = {}

--
-- Globally accessible effects.
--

interop.effects = {}

--
-- Globally accessible keyboard data.
--

-- Initialize global keyboard data.
interop.globalKeyboardData = table.new(6, 0)
for r = 1, 6 do
	interop.globalKeyboardData[r] = table.new(22, 0)
end

function interop.clearGlobalKeyboardData()
	local data = interop.globalKeyboardData
	for r = 1, 6 do
		local dataR = data[r]
		for c = 1, 22 do
			dataR[c] = 0
		end
	end
end

function interop.setGlobalKeyboardColor(row, column, r, g, b)
	interop.globalKeyboardData[row][column] = interop.razerSDK.color(r, g, b)
end

-- Clear initial data.
interop.clearGlobalKeyboardData()

--
-- Module handling.
--

interop.modules = {}

local currentModule = nil

function interop.getCurrentModule()
	return currentModule
end

function interop.setCurrentModule(module)
	if (module == nil) then
		module = interop.modules.default
	end

	if (currentModule == module) then
		return
	end

	if (currentModule and currentModule.onStop) then
		currentModule.onStop()
	end

	currentModule = module

	if (module.onStart) then
		module.onStart()
	end
end

return interop