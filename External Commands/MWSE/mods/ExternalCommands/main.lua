
local socket = require("socket")

local interop = require("ExternalCommands.interop")
local config = require("ExternalCommands.config")

--
-- Register handlers.
--

local function createSandboxEnvironment(package)
	local sandbox = {
		externalCommands = {
			package = package,
		},
	}
	return setmetatable(sandbox, { __index = _G })
end

local function onLuaHandler(package)
	assert(type(package.command) == "string", "Lua package does not have a valid command.")
	local f, message = loadstring(package.command)
	if (not f) then
		error(message)
		return
	end

	local sandbox = createSandboxEnvironment(package)
	setfenv(f, sandbox)
	f()
end
interop.registerHandler("lua", onLuaHandler)

local function onMorrowindScriptHandler(package)
	assert(type(package.command) == "string", "mwscript package does not have a valid command.")
	tes3.runLegacyScript({
		command = package.command,
	})
end
interop.registerHandler("mwscript", onMorrowindScriptHandler)

local function onFileHandler(package)
	assert(type(package.file) == "string", "File must be a string.")

	local sandbox = createSandboxEnvironment(package)
	local f, err = loadfile(string.format("Data Files\\mwse\\mods\\ExternalCommands\\files\\%s.lua", package.file), "t", sandbox)
	if (not f) then
		error(err)
		return
	end
	f()
end
interop.registerHandler("file", onFileHandler)

local function loadPackage(path)
	-- Load the contents of the file.
	local f = io.open(path, "r")
	if (f == nil) then
		return nil
	end
	local fileContents = f:read("*all")
	f:close()
	f = nil

	-- Return decoded json.
	return json.decode(fileContents), fileContents
end

local function handleFile(file)
	local package, contents = loadPackage(file)
	if (not package) then
		error(string.format("Could not parse contents of file as json: %s", contents))
		return
	end

	local handler = interop.getHandler(package.type)
	if (not handler) then
		error(string.format("No handler exists of type '%s'", package.type))
		return
	end

	handler(package)
end

local function handleString(string)
	local package = json.decode(string)
	if (not package) then
		error(string.format("Could not parse contents of string as json: %s", string))
		return
	end

	local handler = interop.getHandler(package.type)
	if (not handler) then
		error(string.format("No handler exists of type '%s'", package.type))
		return
	end

	handler(package)
end

-- Scan for file changes to see if we need to run any.
local function scanForExternalCommands()
	if (not config.enableFileMonitoring) then
		return
	end

	-- Gather external command files.
	local commandFiles = {}
	for file in lfs.dir(config.commandDir) do
		if (string.endswith(file:lower(), ".json")) then
			table.insert(commandFiles, config.commandDir .. "\\" .. file)
		end
	end

	-- Execute them.
	for _, file in ipairs(commandFiles) do
		local success, message = pcall(handleFile, file)
		if (not success) then
			mwse.log("[ExternalCommands] ERROR: Failed to execute file '%s': %s", file, message)
		end

		os.remove(file)
	end
end
event.register(tes3.event.enterFrame, scanForExternalCommands)

-- Listen to internet requests.
local server = assert(socket.bind("*", config.tcpPort))
server:settimeout(0)
local function listenToServer()
	if (not config.enableNetworking) then
		return
	end

	local client = server:accept()
	if (not client) then
		return
	end

	client:settimeout(0)

	local line, err = client:receive()
	if (not err) then
		local success, message = pcall(handleString, line)
		if (not success) then
			mwse.log("[ExternalCommands] ERROR: Failed to execute socket command '%s': %s", line, message)
		end
	end

	client:close()
end
event.register(tes3.event.enterFrame, listenToServer)

