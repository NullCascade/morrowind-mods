
local config = require("Matching Manuscripts.config")
local i18n = require("Matching Manuscripts.i18n")

if (mwse.buildDate == nil or mwse.buildDate < 20220301) then
	-- mwse.log("[Matching Manuscripts] Build date of %s does not meet minimum build date of 20200423.", mwse.buildDate)
	event.register("initialized", function() tes3.messageBox(i18n("updateNeeded")) end)
	return
end

--- @type tes3book?
local lastOpenedBook = nil

--- @param e bookGetTextEventData
local function saveLastOpenedBook(e)
	if (not config.enabled) then
		return
	end

	if (e.book.type == tes3.bookType.book) then
		lastOpenedBook = e.book
	else
		lastOpenedBook = nil
	end
end
event.register("bookGetText", saveLastOpenedBook)

--- @type table<string, niSourceTexture>
local meshPathBookCoverMap = {}

--- @param book tes3book
--- @return niSourceTexture
local function getBookCoverTexture(book)
	if (not config.enabled) then
		return
	end

	local mesh = book.mesh:lower()

	-- Did we already figure out this mesh?
	local cacheHit = meshPathBookCoverMap[mesh]
	if (cacheHit) then
		return cacheHit
	elseif (cacheHit == false) then
		return nil
	end

	-- Look for a valid book texture.
	for node in table.traverse({ book.sceneNode }) do
		--- @cast node niAVObject
		local success, texture = pcall(function() return node.texturingProperty.baseMap.texture end)
		if (success and texture and not string.multifind(texture.fileName:lower(), config.textureBlacklist)) then
			meshPathBookCoverMap[mesh] = texture
			return texture
		end
	end

	-- Ensure that we don't repeat this miss in the future.
	meshPathBookCoverMap[mesh] = false
end

--- @param e uiActivatedEventData
local function onShowBookMenu(e)
	if (not config.enabled) then
		return
	end

	if (lastOpenedBook) then
		local texture = getBookCoverTexture(lastOpenedBook)
		if (texture) then
			local bookNif = e.element:findChild("PartNonDragMenu_main").sceneNode
			bookNif.children[1].texturingProperty.baseMap.texture = texture
		end
	end
end
event.register("uiActivated", onShowBookMenu, { filter = "MenuBook" })

--- @param e uiActivatedEventData
local function onShowJournalMenu(e)
	if (not config.enabled) then
		return
	end

	if (config.journalCover and config.journalCover ~= "") then
		local texture = tes3.loadSourceTexture(config.journalCover)
		if (texture) then
			local bookNif = e.element:findChild("PartNonDragMenu_main").sceneNode
			bookNif.children[1].texturingProperty.baseMap.texture = texture
		end
	end
end
event.register("uiActivated", onShowJournalMenu, { filter = "MenuJournal" })
