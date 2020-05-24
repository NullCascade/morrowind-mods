
if (mwse.buildDate == nil or mwse.buildDate < 20200423) then
	mwse.log("[Matching Manuscripts] Build date of %s does not meet minimum build date of 20200423.", mwse.buildDate)
	event.register("initialized", function() tes3.messageBox("Matching Manuscripts: Please run mwse-updater.exe.") end)
	return
end

local defaultConfig = {
	journalCover = "tx_book_04.tga",
	textureBlacklist = {
		"^tx_book_edge_(.*)%.tga$",
		"^tx_wax_(.*)%.tga$",
	}
}
local config = mwse.loadConfig("Matching Manuscripts", defaultConfig)

local lastOpenedBook = nil
local function saveLastOpenedBook(e)
	if (e.book.type == 0) then
		lastOpenedBook = e.book
	else
		lastOpenedBook = nil
	end
end
event.register("bookGetText", saveLastOpenedBook)

local function traverse(roots)
	local function iter(nodes)
		for i, node in ipairs(nodes or roots) do
			if node then
				coroutine.yield(node)
				local children = node.children
				if children then
					iter(children)
				end
			end
		end
	end
	return coroutine.wrap(iter)
end

local meshPathBookCoverMap = {}
local function getBookCoverTexture(book)
	local mesh = book.mesh:lower()

	-- Did we already figure out this mesh?
	local cacheHit = meshPathBookCoverMap[mesh]
	if (cacheHit) then
		return cacheHit
	elseif (cacheHit == false) then
		return nil
	end

	-- Look for a valid book texture.
	for node in traverse({ book.sceneNode }) do
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
	if (lastOpenedBook) then
		local texture = getBookCoverTexture(lastOpenedBook)
		if (texture) then
			mwse.log("Book texture: %s", texture and texture.fileName or "N/A")
			local bookNif = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main")).sceneNode
			bookNif.children[1]:getProperty(4).maps[1].texture = texture
		end
	end
end
event.register("uiActivated", onShowBookMenu, { filter = "MenuBook" })

local function onShowJournalMenu(e)
	if (config.journalCover and config.journalCover ~= "") then
		local texture = tes3.loadSourceTexture(config.journalCover)
		if (texture) then
			local bookNif = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main")).sceneNode
			bookNif.children[1]:getProperty(4).maps[1].texture = texture
		end
	end
end
event.register("uiActivated", onShowJournalMenu, { filter = "MenuJournal" })

local function registerModConfig()
	
end
event.register("modConfigReady", registerModConfig)
