local rest = require("Chromawind.ChromaSDK.rest")

--- @class ChromaSDKInstance
--- @field session number The session id.
--- @field url string The base URL to send requests to.
local instance = {}

instance.__index = instance

function instance:close()
	local response = rest.send({
		method = "DELETE",
		url = self.url,
	})
	self.session = nil
	self.url = nil
	return response
end

function instance:heartbeat()
	local response = rest.send({
		method = "PUT",
		url = self.url .. "/heartbeat",
	})
	return response.tick
end

function instance:setEffect(effectId)
	local response = rest.send({
		method = "PUT",
		url = self.url .. "/effect",
		data = {
			id = effectId,
		}
	})
end

function instance:setEffects(effectIds)
	local response = rest.send({
		method = "PUT",
		url = self.url .. "/effect",
		data = {
			ids = effectIds,
		}
	})
end

function instance:createKeyboardEffect(effect, param)
	local response = rest.send({
		method = "PUT",
		url = self.url .. "/keyboard",
		data = {
			effect = effect,
			param = param,
		}
	})
	if (response and response.result == 0) then
		return response.id
	else
		error(string.format("Could not create effect: %s", json.encode(response or {}, { indent = true })))
	end
end

function instance:preCreateKeyboardEffect(effect, param)
	local response = rest.send({
		method = "POST",
		url = self.url .. "/keyboard",
		data = {
			effect = effect,
			param = param,
		}
	})
	if (response and response.result == 0) then
		return response.id
	else
		error(string.format("Could not create effect: %s", json.encode(response or {}, { indent = true })))
	end
end

return instance