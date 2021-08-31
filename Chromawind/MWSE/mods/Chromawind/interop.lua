local interop = {}

--
-- Globally accessible effects.
--

interop.effects = {}


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

	mwse.log("Changing module: %s -> %s", currentModule and currentModule.name, module.name)

	if (currentModule and currentModule.onStop) then
		currentModule.onStop()
	end

	currentModule = module

	if (module.onStart) then
		module.onStart()
	end
end

return interop