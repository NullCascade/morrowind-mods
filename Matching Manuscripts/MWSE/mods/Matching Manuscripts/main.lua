
if (mwse.buildDate == nil or mwse.buildDate < 20200423) then
	-- mwse.log("[Matching Manuscripts] Build date of %s does not meet minimum build date of 20200423.", mwse.buildDate)
	event.register("initialized", function() tes3.messageBox("Matching Manuscripts: Please run mwse-updater.exe.") end)
	return
end

local config = require("Matching Manuscripts.config")

local lastOpenedBook = nil
local function saveLastOpenedBook(e)
	if (not config.enabled) then
		return
	end
	
	if (e.book.type == 0) then
		lastOpenedBook = e.book
	else
		lastOpenedBook = nil
	end
end
event.register("bookGetText", saveLastOpenedBook)

local meshPathBookCoverMap = {}
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
		local success, texture = pcall(function() return node:getProperty(0x4).maps[1].texture end)
		if (success and texture and not string.multifind(texture.fileName:lower(), config.textureBlacklist)) then
			meshPathBookCoverMap[mesh] = texture
			return texture
		end
	end

	-- Ensure that we don't repeat this miss in the future.
	meshPathBookCoverMap[mesh] = false
end

local function onShowBookMenu(e)
	if (not config.enabled) then
		return
	end

	if (lastOpenedBook) then
		local texture = getBookCoverTexture(lastOpenedBook)
		if (texture) then
			local bookNif = e.element:findChild("PartNonDragMenu_main").sceneNode
			bookNif.children[1]:getProperty(4).maps[1].texture = texture
		end
	end
end
event.register("uiActivated", onShowBookMenu, { filter = "MenuBook" })

local function onShowJournalMenu(e)
	if (not config.enabled) then
		return
	end

	if (config.journalCover and config.journalCover ~= "") then
		local texture = tes3.loadSourceTexture(config.journalCover)
		if (texture) then
			local bookNif = e.element:findChild("PartNonDragMenu_main").sceneNode
			bookNif.children[1]:getProperty(4).maps[1].texture = texture
		end
	end
end
event.register("uiActivated", onShowJournalMenu, { filter = "MenuJournal" })

-- Handle MCM in another file.
dofile("Matching Manuscripts.mcm")
