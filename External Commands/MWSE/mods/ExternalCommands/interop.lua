
local interop = {}

---	@type table<string, function>
local handlers = {}

--- @param packageType string
--- @param callback function
function interop.registerHandler(packageType, callback)
	assert(packageType, "No package type provided.")
	assert(handlers[packageType] == nil, "This package type has already been registered.")
	assert(type(callback) == "function", "Callback isn't a function.")

	handlers[packageType] = callback
end

--- @param packageType string
--- @return function?
function interop.getHandler(packageType)
	return handlers[packageType]
end

return interop
