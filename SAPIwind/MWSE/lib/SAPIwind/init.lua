local speech = {}

-- Get our DLL.
local sapi = require("SAPIwind.SAPI")
speech.stop = sapi.stop
speech.isPlaying = sapi.isPlaying

-- Custom function to add pronunciation, then do it again lowercase if applicable.
function speech.addProperPronunciation(word, pronunciation)
	if (not sapi.addPronunciation(word, pronunciation)) then
		error(string.format("Failed to parse pronunciation: %s => %s", word, pronunciation))
	end

	local lower = word:lower()
	if (lower ~= word) then
		if (not sapi.addPronunciation(lower, pronunciation)) then
			error(string.format("Failed to parse pronunciation: %s => %s", word, pronunciation))
		end
	end
end

-- Load through all our pronunciation definitions.
local pronunciations = {}
for file in lfs.dir(".\\Data Files\\MWSE\\lib\\SAPIwind\\pronunciations") do
	if string.endswith(file, ".json") then
		local lexicon = json.loadfile(string.format("lib\\SAPIwind\\pronunciations\\%s", file))
		for k, v in pairs(lexicon) do
			pronunciations[k] = v
		end
	end
end

-- Actually add them to the Speech Dictionary.
for k, v in pairs(pronunciations) do
	speech.addProperPronunciation(k, v)
end

-- Allow a mute flag.
speech.muted = false

local function getDialogActor()
	local MenuDialog = tes3ui.findMenu("MenuDialog")
	if (MenuDialog) then
		return MenuDialog:getPropertyObject("PartHyperText_actor")
	end
end

local function getDialogActorOrPlayer()
	return getDialogActor() or tes3.mobilePlayer
end

local substitutions = {
	["<[bB][rR]>"] = "\n",
	["%%[cC][lL][aA][sS][sS]"] = function() return getDialogActorOrPlayer().object.class.name end,
	["%%[nN][aA][mM][eE]"] = function() return getDialogActorOrPlayer().object.name end,
	["%%[pP][cC][cC][lL][aA][sS][sS]"] = function() return tes3.player.object.class.name end,
	["%%[pP][cC][nN][aA][mM][eE]"] = function() return tes3.player.object.name end,
	["%%[pP][cC][rR][aA][cC][eE]"] = function() return tes3.player.object.race.name end,
	["%%[rR][aA][cC][eE]"] = function() return getDialogActorOrPlayer().object.race.name end,
	["%%[cC][eE][lL][lL]"] = function() return tes3.player.cell.name end,
	["%%[fF][aA][cC][tT][iI][oO][nN]"] = function()
		local actor = getDialogActor()
		if (actor) then
			local faction = actor.object.faction
			if (faction) then
				return faction.name
			end
		end
	end,
	["%%[nN][eE][xX][tT][pP][cC][rR][aA][nN][kK]"] = function()
		local actor = getDialogActor()
		if (actor) then
			local faction = actor.object.faction
			if (faction) then
				return faction:getRankName(faction.playerRank + 1)
			end
		end
	end,
	["%%[pP][cC][rR][aA][nN][kK]"] = function()
		local actor = getDialogActor()
		if (actor) then
			local faction = actor.object.faction
			if (faction) then
				return faction:getRankName(faction.playerRank)
			end
		end
	end,
	["%%[rR][aA][nN][kK]"] = function()
		local actor = getDialogActor()
		if (actor) then
			local faction = actor.object.faction
			if (faction) then
				return faction:getRankName(actor.object.factionRank)
			end
		end
	end,
	["[@#]"] = "", -- Remove any other special symbols.
}
function speech.setSubstitution(pattern, replacement) substitutions[pattern] = replacement end

function speech.getSAPIXML(tokensRequired, pitch, volume, speed)
	local xml = ""
	if (tokensRequired) then xml = string.format("%s<voice required=\"%s\" />", xml, tokensRequired) end
	if (pitch) then xml = string.format("%s<pitch absmiddle=\"%d\" />", xml, pitch) end
	if (volume) then xml = string.format("%s<volume level=\"%d\" />", xml, volume) end
	if (speed) then xml = string.format("%s<rate speed=\"%d\" />", xml, speed) end
	return xml
end

function speech.speak(text, params)
	if (speech.muted) then
		return
	end

	-- Make sure we were given text.
	assert(text)

	-- Apply filtering.
	local line = text
	for pattern, replacement in pairs(substitutions) do
		line = string.gsub(line, pattern, replacement)
	end

	-- Append speech data.
	local params = params or {}
	return sapi.speak(speech.getSAPIXML(params.tokensRequired, params.pitch, params.volume, params.speed) .. line)
end

return speech