
local config = require("Selection Details.config")
local i18n = require("Selection Details.i18n")

local variableTypeToFullName = {
	f = i18n("variableType.float"),
	l = i18n("variableType.long"),
	s = i18n("variableType.short"),
}

local publicFacingObjectTypeNames = {
	[tes3.objectType.activator] = i18n("objectType.activator"),
	[tes3.objectType.alchemy] = i18n("objectType.alchemy"),
	[tes3.objectType.ammunition] = i18n("objectType.ammunition"),
	[tes3.objectType.apparatus] = i18n("objectType.apparatus"),
	[tes3.objectType.armor] = i18n("objectType.armor"),
	[tes3.objectType.book] = i18n("objectType.book"),
	[tes3.objectType.class] = i18n("objectType.class"),
	[tes3.objectType.clothing] = i18n("objectType.clothing"),
	[tes3.objectType.container] = i18n("objectType.container"),
	[tes3.objectType.creature] = i18n("objectType.creature"),
	[tes3.objectType.door] = i18n("objectType.door"),
	[tes3.objectType.enchantment] = i18n("objectType.enchantment"),
	[tes3.objectType.faction] = i18n("objectType.faction"),
	[tes3.objectType.ingredient] = i18n("objectType.ingredient"),
	[tes3.objectType.leveledCreature] = i18n("objectType.leveledCreature"),
	[tes3.objectType.leveledItem] = i18n("objectType.leveledItem"),
	[tes3.objectType.light] = i18n("objectType.light"),
	[tes3.objectType.lockpick] = i18n("objectType.lockpick"),
	[tes3.objectType.miscItem] = i18n("objectType.miscItem"),
	[tes3.objectType.npc] = i18n("objectType.npc"),
	[tes3.objectType.probe] = i18n("objectType.probe"),
	[tes3.objectType.reference] = i18n("objectType.reference"),
	[tes3.objectType.repairItem] = i18n("objectType.repairItem"),
	[tes3.objectType.script] = i18n("objectType.script"),
	[tes3.objectType.sound] = i18n("objectType.sound"),
	[tes3.objectType.soundGenerator] = i18n("objectType.soundGenerator"),
	[tes3.objectType.spell] = i18n("objectType.spell"),
	[tes3.objectType.static] = i18n("objectType.static"),
	[tes3.objectType.weapon] = i18n("objectType.weapon"),
}

local indentationLevel = 0

--- comment
--- @param parent tes3uiElement
--- @param name string
--- @param value any
--- @param clickCallback function?
--- @return tes3uiElement
--- @return tes3uiElement
--- @return tes3uiElement
local function createInfoLabel(parent, name, value, clickCallback)
	local infoBlock = parent:createBlock({ id = "Info" })
	infoBlock.autoHeight = true
	infoBlock.autoWidth = true
	infoBlock.flowDirection = "left_to_right"
	infoBlock.paddingLeft = indentationLevel * 10

	local nameElement = infoBlock:createLabel({ id = "Name", text = string.format("%s:", name) })
	nameElement.color = tes3ui.getPalette("disabled_color")
	nameElement.borderRight = 6

	local valueElement = infoBlock:createLabel({ id = "Value", text = tostring(value) })
	if (clickCallback) then
		valueElement.color = tes3ui.getPalette("link_color")
		valueElement:register(tes3.uiEvent.mouseClick, clickCallback)
	end

	return infoBlock, nameElement, valueElement
end

local function jsonExceptionValueToString(reason, value, state, defaultmessage)
	return string.format([["%s"]], tostring(value))
end

--- comment
--- @param object tes3object
--- @return string
local function getObjectIdWithSource(object)
	return string.format("%s (%s)", object.id, object.sourceMod)
end

--- comment
--- @param vector tes3vector3
--- @return string
local function prettyVectorToString(vector)
	return string.format("%.2f, %.2f, %.2f", vector.x, vector.y, vector.z)
end

--- comment
--- @param sceneNode niNode
--- @return table
local function getAllTexturesUsed(sceneNode)
	-- Go through and show any associated textures, using :lower() to ensure no weird duplicates
	local usedTextures = {}
	for node in table.traverse({ sceneNode }, "children") do
		local texturingProperty = node.texturingProperty
		if (texturingProperty and texturingProperty.maps[1]) then
			for _, map in ipairs(texturingProperty.maps) do
				if (map and map.texture and map.texture.fileName) then
					usedTextures[map.texture.fileName:lower()] = map.texture.fileName
				end
			end
		end
	end

	-- Sort the textures alphabetically
	local texturesSorted = {}
	for _, v in pairs(usedTextures) do
		table.insert(texturesSorted, v)
	end
	table.sort(texturesSorted, function(a, b) return a:lower() < b:lower() end)

	return texturesSorted
end

--- comment
--- @param str string
--- @return string
local function getPathRemoveDataFilesPrefix(str)
	return string.gsub(str, "^Data Files\\", "")
end

--- comment
--- @param prefix string
--- @param str string
--- @return string
local function conditionalAddPrefix(prefix, str)
	if (not string.startswith(str:lower(), prefix:lower())) then
		return prefix .. str
	end
	return str
end

--- comment
--- @param prefix string
--- @param path string
--- @return string
--- @return string
--- @return string
local function getFileSourceWithBSA(prefix, path)
	local source, path = tes3.getFileSource(conditionalAddPrefix(prefix, path))
	local bsaFile = nil
	if (source == "bsa") then
		local archive = tes3.bsaLoader:findFile(path)
		if (archive) then
			bsaFile = archive.path:sub(12)
		end
	end
	return source, path, bsaFile
end

--- @param reference tes3reference
local function updateInformationPane(reference)
	local menu = tes3ui.findMenu("MenuSelectionDetails")

	-- Clear current data.
	menu:destroyChildren()

	-- Display a waiting message if no reference is selected.
	if (not reference) then
		menu.visible = false
		return
	end

	-- Are we only showing information when control is held?
	if (config.requireControlKey and not tes3.worldController.inputController:isControlDown()) then
		menu.visible = false
		return
	end

	local scrollPane = menu:createVerticalScrollPane({ id = "ScrollContents" })
	scrollPane.autoHeight = true
	scrollPane.autoWidth = true
	local outerFrame = scrollPane:findChild("PartScrollPane_outer_frame")
	outerFrame.autoHeight = true
	outerFrame.autoWidth = true
	local scrollContents = scrollPane:getContentElement()
	scrollContents.autoHeight = true
	scrollContents.autoWidth = true
	scrollContents.paddingAllSides = 4

	-- Reset indentation level in case things break.
	indentationLevel = 0

	-- Basic information.
	local baseObject = reference.baseObject
	createInfoLabel(scrollContents, i18n("label.reference"), getObjectIdWithSource(reference))
	createInfoLabel(scrollContents, i18n("label.baseObject"), getObjectIdWithSource(baseObject))
	createInfoLabel(scrollContents, i18n("label.type"), publicFacingObjectTypeNames[baseObject.objectType])
	createInfoLabel(scrollContents, i18n("label.cell"), reference.cell.editorName)

	-- Show used meshes/textures.
	local meshSource, meshPath, bsaFile = getFileSourceWithBSA("meshes\\", baseObject.mesh)
	createInfoLabel(scrollContents, i18n("label.mesh"), string.format("%s (%s)", getPathRemoveDataFilesPrefix(meshPath), bsaFile or meshSource))
	for _, texture in ipairs(getAllTexturesUsed(reference.sceneNode)) do
		indentationLevel = indentationLevel + 1
		local textureSource, texturePath, bsaFile = getFileSourceWithBSA("textures\\", texture)
		createInfoLabel(scrollContents, i18n("label.texture"), string.format("%s (%s)", getPathRemoveDataFilesPrefix(texturePath or texture), bsaFile or textureSource or i18n("unknown")))
		indentationLevel = indentationLevel - 1
	end

	-- Ownership information
	local owner, ownerReq = tes3.getOwner({ reference = reference })
	if (owner) then
		createInfoLabel(scrollContents, i18n("label.owner"), getObjectIdWithSource(owner))
		indentationLevel = indentationLevel + 1
		if (owner.objectType == tes3.objectType.faction) then
			createInfoLabel(scrollContents, i18n("label.rankRequired"), string.format("%s (%d)", owner:getRankName(ownerReq), ownerReq))
		elseif (owner.objectType == tes3.objectType.npc) then
			if (ownerReq) then
				createInfoLabel(scrollContents, i18n("label.requiredGlobal"), getObjectIdWithSource(ownerReq))
			end
		end
		indentationLevel = indentationLevel - 1
	end

	-- Leveled spawn information.
	local leveledFrom = reference.leveledBaseReference
	if (leveledFrom) then
		createInfoLabel(scrollContents, i18n("label.leveledReference"), getObjectIdWithSource(leveledFrom))
		indentationLevel = indentationLevel + 1
		createInfoLabel(scrollContents, i18n("label.cell"), leveledFrom.cell.editorName)
		createInfoLabel(scrollContents, i18n("label.position"), prettyVectorToString(leveledFrom.position))
		indentationLevel = indentationLevel - 1
	end

	-- Script information.
	local script = baseObject.script
	if (script) then
		createInfoLabel(scrollContents, i18n("label.script"), getObjectIdWithSource(script))
		indentationLevel = indentationLevel + 1
		local variables = reference.context:getVariableData()
		local variableNames = table.keys(variables, function(a, b) return a:lower() < b:lower() end)
		for _, name in ipairs(variableNames) do
			local data = variables[name]
			createInfoLabel(scrollContents, string.format("%s (%s)", name, variableTypeToFullName[data.type]), data.value)
		end
		indentationLevel = indentationLevel - 1
	end

	-- Security information.
	local lockNode = reference.lockNode
	if (lockNode) then
		createInfoLabel(scrollContents, i18n("label.locked"), string.format("%s (%d)", lockNode.locked, lockNode.level))
		indentationLevel = indentationLevel + 1
		if (lockNode.trap) then
			createInfoLabel(scrollContents, i18n("label.trap"), getObjectIdWithSource(lockNode.trap))
		end
		if (lockNode.key) then
			createInfoLabel(scrollContents, i18n("label.key"), getObjectIdWithSource(lockNode.key))
		end
		indentationLevel = indentationLevel - 1
	end

	-- Show lua data.
	local luaData = reference.data
	if (luaData and not table.empty(luaData, true)) then
		createInfoLabel(scrollContents, i18n("label.luaData"), "[click to copy]", function()
			local serialized = string.format("Lua data for %s:\n%s", reference, json.encode(luaData, { indent = true, exception = jsonExceptionValueToString }))
			mwse.log(serialized)
			os.setClipboardText(serialized)
			tes3.messageBox(i18n("copiedToClipboardAndLog"))
		end)
	end

	-- Show temp lua data.
	local luaTempData = reference.tempData
	if (luaTempData and not table.empty(luaTempData, true)) then
		createInfoLabel(scrollContents, i18n("label.tempLuaData"), i18n("[click to copy]"), function()
			local serialized = string.format("Temporary lua data for %s:\n%s", reference, json.encode(luaTempData, { indent = true, exception = jsonExceptionValueToString }))
			mwse.log(serialized)
			os.setClipboardText(serialized)
			tes3.messageBox(i18n("copiedToClipboardAndLog"))
		end)
	end

	-- Hide the scroll bar if it isn't needed.
	local scrollBar = scrollPane:findChild("PartScrollPane_vert_scrollbar")
	menu:updateLayout()
	scrollBar.visible = scrollContents.height > menu.maxHeight

	menu.visible = true
end

--- @type tes3reference?
local previousSelectedReference = nil

--- @param e tes3uiEventData
local function onConsoleUpdated(e)
	local menu = tes3ui.findMenu("MenuSelectionDetails")
	if (not menu) then
		return
	end

	local console = e.source
	menu.visible = console.visible

	if (menu.visible) then
		local currentReference = console:getPropertyObject("MenuConsole_current_ref") --- @type tes3reference?
		if (currentReference ~= previousSelectedReference) then
			previousSelectedReference = currentReference
			updateInformationPane(currentReference)
		end
	end

	menu:updateLayout()
end

local function createInformationPane()
	local oldMenu = tes3ui.findMenu("MenuSelectionDetails")
	if (oldMenu) then
		oldMenu:destroy()
		oldMenu = nil
	end

	local viewportWidth, viewportHeight = tes3ui.getViewportSize()

	local menu = tes3ui.createMenu({ id = "MenuSelectionDetails", fixedFrame = true })
	menu:destroyChildren()
	menu.disabled = true
    menu.absolutePosAlignX = 0
    menu.absolutePosAlignY = 0
	menu.borderLeft = 40
	menu.borderTop = 40
    menu.color = { 0, 0, 0 }
    menu.alpha = 0.8
	menu.autoWidth = true
    menu.autoHeight = true
	menu.maxWidth = viewportWidth / 3
	menu.maxHeight = viewportHeight * (3/4)
	menu.flowDirection = "top_to_bottom"

	menu.visible = false

	menu:updateLayout()
end
event.register(tes3.event.initialized, createInformationPane)

local function onConsoleActivated()
	local console = tes3ui.findMenu("MenuConsole")
	console:registerAfter("update", onConsoleUpdated)
end
event.register(tes3.event.uiActivated, onConsoleActivated, { filter = "MenuConsole"})
