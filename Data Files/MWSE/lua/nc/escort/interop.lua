
--[[

	Interop library for Easy Escort.

	To use this module, use the following:

	local easyEscortInterop = include("nc.escort.interop")
	if (easyEscortInterop) then
		easyEscortInterop.addToBlacklist("blim-dim")
	end

]]--

local this = {}

local blacklist = {}

function this.addToBlacklist(id)
	table.insert(blacklist, id)
end

function this.removeFromBlacklist(id)
	table.removevalue(blacklist, id)
end

function this.blacklistContains(id)
	return (table.find(blacklist, id) ~= nil)
end

return this
