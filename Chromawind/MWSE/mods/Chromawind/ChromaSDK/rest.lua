local rest = {}

local http = require("socket.http")
local ltn12 = require("ltn12")

--- 
--- @param params table
--- @return table
function rest.send(params)
	local request = json.encode(params.data)
	local response = {}

	local result, response_code, response_headers, response_status = http.request({
		method = params.method,
		url = params.url,
		source = ltn12.source.string(request),
		headers = {
			["content-type"] = params.contentType or "application/json",
			["content-length"] = params.contentLength or tostring(#request)
		},
		sink = ltn12.sink.table(response)
	})

	local json, loc, err = json.decode(table.concat(response))
	if (not json) then
		mwse.log("No response from request: %s", request)
	end
	return json
end

return rest