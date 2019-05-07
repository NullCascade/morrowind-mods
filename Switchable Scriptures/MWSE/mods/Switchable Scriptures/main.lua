
-- A list of all books that the current meshes support.
local supportedBooks = {}

-- A list of all books that are closed by default.
local openByDefaultBooks = {}

-- Cache the open/close sounds.
local bookOpenSound = nil
local bookCloseSound = nil

-- Load our config, and set default values if needed.
local config = mwse.loadConfig("Switchable Scriptures") or {}
config.toggleKey = config.toggleKey or {
	keyCode = tes3.scanCode.b,
	isShiftDown = false,
	isAltDown = false,
	isControlDown = false,
}

-- Determines if a book is supported, and figures out if it is initially open or closed.
local function isBookSupported(book)
	-- This isn't a book...
	if (book.objectType ~= tes3.objectType.book) then
		return false
	end

	-- We already know the answer!
	local result = supportedBooks[book]
	if (result ~= nil) then
		return result
	end

	-- Figure out the default open/closed state.
	local openByDefault = openByDefaultBooks[book]
	if (openByDefault == nil) then
		local switchNode = book.sceneNode.children[1]
		if (switchNode.name == "BookSwitch") then
			local firstNodeName = switchNode.children[1].name
			if (firstNodeName == "Open") then
				openByDefault = true
			elseif (firstNodeName == "Closed") then
				openByDefault = false
			end
		end

		-- Was this a valid book?
		if (openByDefault ~= nil) then
			result = true
			openByDefaultBooks[book] = openByDefault
		else
			result = false
		end
	end

	-- Cache the result for future lookups so we don't have to dive into the mesh.
	supportedBooks[book] = result
	return result
end

-- Returns if the book's mesh is open by default.
local function isBookOpenByDefault(book)
	if (isBookSupported(book) == false) then
		return
	end

	return openByDefaultBooks[book]
end

-- Returns if the book is *currently* open.
local function isBookOpen(ref)
	if (isBookSupported(ref.object) == false) then
		return
	end

	if (isBookOpenByDefault(ref.object)) then
		return ref.sceneNode.children[1].switchIndex == 0
	else
		return ref.sceneNode.children[1].switchIndex ~= 0
	end
end

-- Sets the book as closed/open, and optionally plays a sound.
local function setBookReferenceClosed(ref, closed, playSound)
	if (isBookSupported(ref.object) == false) then
		return
	end

	local switchNode = ref.sceneNode.children[1]
	if (isBookOpenByDefault(ref.object)) then
		switchNode.switchIndex = closed and 1 or 0
	else
		switchNode.switchIndex = closed and 0 or 1
	end

	ref.data.bookSwitchState = switchNode.switchIndex
	ref.modified = true

	if (playSound) then
		if (isBookOpen(ref)) then
			bookOpenSound:play()
		else
			bookCloseSound:play()
		end
	end
end

-- Flips the current open/closed state of a book, and plays a sound.
local function toggleBookReferenceClosed(ref, playSound)
	if (isBookSupported(ref.object) == false) then
		return
	end

	local switchNode = ref.sceneNode.children[1]
	if (switchNode.switchIndex == 0) then
		switchNode.switchIndex = 1
	else
		switchNode.switchIndex = 0
	end

	ref.data.bookSwitchState = switchNode.switchIndex
	ref.modified = true

	if (playSound) then
		if (isBookOpen(ref)) then
			bookOpenSound:play()
		else
			bookCloseSound:play()
		end
	end
end

-- Generic function for performing keybind tests.
local function keybindTest(b, e)
	return (b.keyCode == e.keyCode) and (b.isShiftDown == e.isShiftDown) and (b.isAltDown == e.isAltDown) and (b.isControlDown == e.isControlDown)
end

local function onKeyDown(e)
	-- We don't do anything in menu mode.
	if (tes3ui.menuMode()) then
		return
	end

	-- Test our keybind.
	if (not keybindTest(config.toggleKey, e)) then
		return
	end
	
	-- Is this a supported book?
	local target = tes3.getPlayerTarget()
	if (target == nil or isBookSupported(target.object) == false) then
		return
	end

	-- Toggle the book!
	toggleBookReferenceClosed(target, true)
end
event.register("keyDown", onKeyDown)

-- Callback for when a new scene node is created for a reference.
-- We'll use it to set the closed state so it's synced between saves.
local function onReferenceSceneNodeCreated(e)
	local ref = e.reference
	if (isBookSupported(ref.object) == false) then
		return
	end

	-- No item data? Set it as closed by default.
	local itemData = ref.attachments.variables
	if (itemData == nil) then
		setBookReferenceClosed(ref, true, false)
		return
	end

	-- Do we have a saved state? Set it.
	local switchIndex = ref.data.bookSwitchState
	if (switchIndex ~= nil) then
		ref.sceneNode.children[1].switchIndex = switchIndex
	end
end
event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated)

-- Called when a reference is about to be added to the inventory.
-- We'll clear our userdata so that our data won't make items unstack.
local function onConvertReferenceToItem(e)
	local ref = e.reference
	if (isBookSupported(ref.object) == false) then
		return
	end

	ref.data.bookSwitchState = nil
end
event.register("convertReferenceToItem", onConvertReferenceToItem)

-- When game data is initialized, we'll cache some often-used data.
local function onInitialized()
	bookOpenSound = tes3.getSound("book open")
	bookCloseSound = tes3.getSound("book close")
end
event.register("initialized", onInitialized)

--
-- Mod Config Menu
--

local function registerModConfig()
	local easyMCM = include("easyMCM.EasyMCM")
	if (easyMCM == nil) then
		return
	end

	local template = easyMCM.createTemplate("Scriptable Scriptures")
	template:saveOnClose("Scriptable Scriptures", config)

	local page = template:createPage()
	page:createKeyBinder{
		label = "Assign Keybind",
		allowCombinations = true,
		variable = easyMCM.createTableVariable{
			id = "toggleKey",
			table = config,
			defaultSetting = {
				keyCode = tes3.scanCode.b,
				isShiftDown = false,
				isAltDown = false,
				isControlDown = false,
			}
		}
	}

	easyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)
