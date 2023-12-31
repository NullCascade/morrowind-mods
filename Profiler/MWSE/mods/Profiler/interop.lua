local jit_profile = require("jit.profile")

local interop = {}

local currentDumps = {}

function interop.reset()
	currentDumps = {}
end

function interop.start()
	jit_profile.start("l", function(thread, fmt, depth)
		local line = jit_profile.dumpstack(thread, "pl", 1)
		local data = currentDumps[line]
		if (not data) then
			data = { count = 0 }
			currentDumps[line] = data
		end
		data.count = data.count + 1
	end)
end

function interop.stop()
	jit_profile.stop()
end

function interop.getSortedLinesByCount()
	return table.keys(currentDumps, function(a, b) return currentDumps[a].count > currentDumps[b].count end)
end

function interop.formatLine(line)
	return string.gsub(line, "^.\\", "")
end

function interop.dumpToLog()
	local sortedHits = interop.getSortedLinesByCount()

	local resultsTotalCount = 0
	for _, data in pairs(currentDumps) do
		resultsTotalCount = resultsTotalCount + data.count
	end

	mwse.log("Profiling results:")
	for _, line in ipairs(sortedHits) do
		local count = currentDumps[line].count
		mwse.log("  %s : %d (%.0f%%)", interop.formatLine(line), count, (count / resultsTotalCount) * 100)
	end
end

function interop.getResults()
	return currentDumps
end

return interop