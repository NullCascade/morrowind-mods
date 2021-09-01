local sdk = {}

local socket = require("socket")
local bit = require("bit")

local rest = require("Chromawind.ChromaSDK.rest")
sdk.rest = rest

local instance = require("Chromawind.ChromaSDK.instance")

function sdk.get()
	return rest.send({
		method = "GET",
		url = "http://localhost:54235/razer/chromasdk",
	})
end

--- Initializes Chroma SDK.
---
--- Dev Portal: https://assets.razerzone.com/dev_portal/REST/html/md__r_e_s_t_external_01_8init.html
--- @param params table
--- @return ChromaSDKInstance
function sdk.new(params)
	local response = rest.send({
		method = "POST",
		url = "http://localhost:54235/razer/chromasdk",
		data = {
			title = params.title,
			description = params.description,
			author =params.author,
			device_supported = params.device_supported,
			category = params.category,
		},
	})

	if (not response or response.result == 0 or not response.uri) then
		error(string.format("Could not initialize Chroma SDK. Response: %s", json.encode(response or {}, { indent = true })))
	end

    return setmetatable({ session = response.sessionid, url = response.uri }, instance)
end

local lshift, floor = bit.lshift, math.floor

function sdk.color(r, g, b)
	return floor(r*255) + lshift(floor(g*255), 8) + lshift(floor(b*255), 16)
end

function sdk.colorEffect(r, g, b)
	return bit.bor(floor(r*255) + lshift(floor(g*255), 8) + lshift(floor(b*255), 16), 0x1000000)
end

sdk.keys = require("Chromawind.ChromaSDK.key")
sdk.scanCodeMap = require("Chromawind.ChromaSDK.scanKeyMap")

function sdk.scanCodeToKey(scanCode)
	return sdk.scanCodeMap[scanCode]
end

function sdk.getRowColumnForKey(key)
	local result = sdk.keys[key]
	if (result) then
		return unpack(result)
	end
end

function sdk.getRowColumnForScanCode(scanCode)
	local key = sdk.scanCodeToKey(scanCode)
	if (not key) then
		return
	end

	local result = sdk.keys[key]
	if (result) then
		return unpack(result)
	end
end

return sdk