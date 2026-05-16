local modName = "Scene Inspector"
local dumpPath = "Data Files\\MWSE\\tmp\\scene_dump.json"
local sceneTypes = require("Scene Inspector.types")
local rttiAccentColor = { 0.55, 0.7, 0.85 }

local state = {
	expanded = {},
	nodeMap = {},
	selectedPath = nil,
	rootIndex = 1,
	rootEntries = {},
	dumpButtonMinWidth = nil,
}

local ids = {}
local getNodeCaption
local buildRootEntries
local refreshTree
local serializeNode

local function leaveInspectorMenuMode()
	local menu = tes3ui.findMenu(ids.menu)
	if not menu then
		return
	end

	menu:saveMenuPosition()

	tes3ui.leaveMenuMode()
end

local function safeIndex(value, key)
	local ok, result = pcall(function()
		return value[key]
	end)
	if not ok then return end
	return result
end

local function safeCall(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn, ...)
	return ok and result or nil
end

local function getRTTIName(object)
	local rtti = safeIndex(object, "RTTI") or safeIndex(object, "runTimeTypeInformation")
	local name = safeIndex(rtti, "name")
	return name or "<unknown>"
end

local function formatObjectName(object)
	local name = safeIndex(object, "name")
	if name and name ~= "" then
		return name
	end
	return "<unnamed>"
end

local function formatReference(reference)
	if not reference then
		return "nil"
	end
	local object = safeIndex(reference, "object")
	local objectId = safeIndex(object, "id")
	local objectName = safeIndex(object, "name")
	local cell = safeIndex(safeIndex(reference, "cell"), "id")
	local label = objectName or objectId or tostring(reference)
	if objectId and objectId ~= label then
		label = string.format("%s (%s)", label, objectId)
	end
	if cell then
		label = string.format("%s @ %s", label, cell)
	end
	return label
end

local function formatValue(value)
	local valueType = type(value)
	if value == nil or valueType == "number" or valueType == "boolean" or valueType == "string" then
		return value
	end
	return tostring(value)
end

local function collectChildren(node)
	local results = {}
	local children = safeIndex(node, "children") or {}
	for index, child in pairs(children) do
		if type(index) == "number" and child then
			table.insert(results, { index = index, node = child })
		end
	end
	table.sort(results, function(a, b)
		return a.index < b.index
	end)
	return results
end

local function collectPropertyList(head, limit)
	local results = {}
	local current = head
	local seen = {}
	local remaining = limit or 64
	while current and remaining > 0 do
		local key = tostring(current)
		if seen[key] then
			break
		end
		seen[key] = true
		local property = safeIndex(current, "data")
		if property then
			table.insert(results, property)
		end
		current = safeIndex(current, "next")
		remaining = remaining - 1
	end
	return results
end

local function collectControllerChain(head, limit)
	local results = {}
	local current = head
	local seen = {}
	local remaining = limit or 64
	while current and remaining > 0 do
		local key = tostring(current)
		if seen[key] then
			break
		end
		seen[key] = true
		table.insert(results, current)
		current = safeIndex(current, "nextController")
		remaining = remaining - 1
	end
	return results
end

local function collectExtraDataChain(head, limit)
	local results = {}
	local current = head
	local seen = {}
	local remaining = limit or 64
	while current and remaining > 0 do
		local key = tostring(current)
		if seen[key] then
			break
		end
		seen[key] = true
		table.insert(results, current)
		current = safeIndex(current, "next")
		remaining = remaining - 1
	end
	return results
end

local function getCurrentRootEntry()
	return state.rootEntries[state.rootIndex]
end

local function isCursorInsideMenu(menu)
	if not menu then return false end
	local cursor = tes3.getCursorPosition()
	local left = menu.positionX
	local top = menu.positionY
	local right = left + menu.width
	local bottom = top - menu.height
	return cursor.x >= left and cursor.x <= right and cursor.y >= bottom and cursor.y <= top
end

local function notifyMenuContentsChanged(menu)
	local treeScroll = menu:findChild(ids.treePane)
	if treeScroll and treeScroll.widget then
		treeScroll.widget:contentsChanged()
	end

	local detailScroll = menu:findChild(ids.detailPane)
	if detailScroll and detailScroll.widget then
		detailScroll.widget:contentsChanged()
	end

	menu:updateLayout()
end

local function isShiftDown()
	return tes3.worldController.inputController:isShiftDown()
end

local function isAltDown()
	return tes3.worldController.inputController:isAltDown()
end

local function getDumpMode()
	if isShiftDown() then
		return "all"
	end
	if isAltDown() then
		return "visible"
	end
	return "selected"
end

local function getDumpButtonText()
	local mode = getDumpMode()
	if mode == "all" then
		return "Dump All"
	end
	if mode == "visible" then
		return "Dump Visible"
	end
	return "Dump Selected"
end

local function getDumpButtonTexts()
	return {
		"Dump Selected",
		"Dump Visible",
		"Dump All",
	}
end

local function collectRTTILineage(node)
	local rtti = safeIndex(node, "RTTI") or safeIndex(node, "runTimeTypeInformation")
	local lineage = {}
	local guard = 12
	while rtti and guard > 0 do
		table.insert(lineage, safeIndex(rtti, "name") or "<unknown>")
		rtti = safeIndex(rtti, "parent")
		guard = guard - 1
	end
	return lineage
end

local function serializeProperties(node)
	local serialized = {}
	for _, property in ipairs(collectPropertyList(safeIndex(node, "properties"))) do
		table.insert(serialized, {
			type = formatValue(safeIndex(property, "type")),
			rtti = getRTTIName(property),
			name = safeIndex(property, "name"),
			flags = formatValue(safeIndex(property, "propertyFlags")),
			pointer = tostring(property),
		})
	end
	return serialized
end

local function serializeControllers(node)
	local serialized = {}
	for _, controller in ipairs(collectControllerChain(safeIndex(node, "controller"))) do
		table.insert(serialized, {
			rtti = getRTTIName(controller),
			active = formatValue(safeIndex(controller, "active")),
			frequency = formatValue(safeIndex(controller, "frequency")),
			phase = formatValue(safeIndex(controller, "phase")),
			target = formatValue(safeIndex(controller, "target")),
			pointer = tostring(controller),
		})
	end
	return serialized
end

local function serializeExtraData(node)
	local serialized = {}
	for _, extraData in ipairs(collectExtraDataChain(safeIndex(node, "extraData"))) do
		table.insert(serialized, {
			rtti = getRTTIName(extraData),
			name = safeIndex(extraData, "name"),
			genericData = formatValue(safeIndex(extraData, "genericData")),
			pointer = tostring(extraData),
		})
	end
	return serialized
end

local function shouldIncludeChildren(path, dumpMode)
	if dumpMode == "all" then
		return true
	end
	return state.expanded[path] == true
end

local function getSlotIndexFromPath(path)
	local slotIndex = path:match("/(%d+):[^/]+$")
	if slotIndex then
		return tonumber(slotIndex)
	end
	return nil
end

local function getNodeChainToRoot(node, root)
	local chain = {}
	local current = node

	while current do
		table.insert(chain, 1, current)
		if current == root or tostring(current) == tostring(root) then
			return chain
		end
		current = safeIndex(current, "parent")
	end

	return nil
end

local function getChildPath(parentPath, parentNode, childNode)
	for _, childEntry in ipairs(collectChildren(parentNode)) do
		if childEntry.node == childNode or tostring(childEntry.node) == tostring(childNode) then
			return string.format("%s/%d:%s", parentPath, childEntry.index, tostring(childNode))
		end
	end
	return nil
end

local function selectNodeInCurrentRoot(node)
	local entry = getCurrentRootEntry()
	if not entry or not entry.node or not node then
		return false
	end

	local chain = getNodeChainToRoot(node, entry.node)
	if not chain then
		return false
	end

	local rootPath = entry.label
	local expanded = {
		[rootPath] = true,
	}
	local currentPath = rootPath

	for i = 2, #chain do
		local parentNode = chain[i - 1]
		local childNode = chain[i]
		local childPath = getChildPath(currentPath, parentNode, childNode)
		if not childPath then
			return false
		end

		if i < #chain then
			expanded[childPath] = true
		end
		currentPath = childPath
	end

	state.expanded = expanded
	state.selectedPath = currentPath
	return true
end

--- @param e mouseButtonDownEventData
local function raySelectAtCursor(e)
	if e.button ~= 0 then
		return
	end

	if not tes3.menuMode() then
		return
	end

	local menu = tes3ui.findMenu(ids.menu)
	if not menu or isCursorInsideMenu(menu) then
		return
	end

	buildRootEntries()
	local entry = getCurrentRootEntry()
	if not entry or not entry.node then
		return
	end

	local camera = tes3.worldController.worldCamera.cameraData.camera
	if not camera then
		return
	end

	local position, direction = tes3.getCamera():windowPointToRay(tes3.getCursorPosition())
	local hit = tes3.rayTest({
		position = position,
		direction = direction,
		accurateSkinned = true,
		root = entry.node,
	})
	if not hit or not hit.object then
		return
	end

	local selected = selectNodeInCurrentRoot(hit.object)
	if not selected then
		local hitReference = hit.reference
		local sceneNode = hitReference and hitReference.sceneNode
		if sceneNode then
			selected = selectNodeInCurrentRoot(sceneNode)
		end
	end

	if selected then
		refreshTree()
		local liveMenu = tes3ui.findMenu(ids.menu)
		if liveMenu then
			notifyMenuContentsChanged(liveMenu)
		end
	end
end

local function serializeSelectedLineage(selectedPath)
	local ancestryPaths = {}
	local currentPath = selectedPath
	while currentPath do
		table.insert(ancestryPaths, 1, currentPath)
		currentPath = currentPath:match("^(.*)/%d+:[^/]+$")
	end

	local function buildNode(index)
		local path = ancestryPaths[index]
		local node = state.nodeMap[path]
		if not node then
			return nil
		end

		local serialized = serializeNode(node, path, "selected", getSlotIndexFromPath(path))
		if index < #ancestryPaths then
			serialized.children = { buildNode(index + 1) }
			serialized.childCount = 1
		else
			serialized.children = {}
			serialized.childCount = 0
		end
		return serialized
	end

	return buildNode(1)
end

serializeNode = function(node, path, dumpMode, slotIndex)
	local reference = safeCall(safeIndex(node, "getGameReference"), node)
	local childEntries = collectChildren(node)
	local serializedChildren = {}

	if shouldIncludeChildren(path, dumpMode) then
		for _, childEntry in ipairs(childEntries) do
			table.insert(
				serializedChildren,
				serializeNode(
					childEntry.node,
					string.format("%s/%d:%s", path, childEntry.index, tostring(childEntry.node)),
					dumpMode,
					childEntry.index
				)
			)
		end
	end

	return {
		path = path,
		slotIndex = slotIndex,
		rtti = getRTTIName(node),
		rttiLineage = collectRTTILineage(node),
		name = safeIndex(node, "name"),
		caption = getNodeCaption(node, slotIndex),
		pointer = tostring(node),
		refCount = formatValue(safeIndex(node, "refCount")),
		flags = formatValue(safeIndex(node, "flags")),
		appCulled = formatValue(safeIndex(node, "appCulled")),
		parentName = safeIndex(safeIndex(node, "parent"), "name"),
		translation = {
			x = formatValue(safeIndex(safeIndex(node, "translation"), "x")),
			y = formatValue(safeIndex(safeIndex(node, "translation"), "y")),
			z = formatValue(safeIndex(safeIndex(node, "translation"), "z")),
		},
		scale = formatValue(safeIndex(node, "scale")),
		rotation = formatValue(safeIndex(node, "rotation")),
		worldTransform = formatValue(safeIndex(node, "worldTransform")),
		worldBoundOrigin = {
			x = formatValue(safeIndex(safeIndex(node, "worldBoundOrigin"), "x")),
			y = formatValue(safeIndex(safeIndex(node, "worldBoundOrigin"), "y")),
			z = formatValue(safeIndex(safeIndex(node, "worldBoundOrigin"), "z")),
		},
		worldBoundRadius = formatValue(safeIndex(node, "worldBoundRadius")),
		gameReference = formatReference(reference),
		childCount = #childEntries,
		properties = serializeProperties(node),
		controllers = serializeControllers(node),
		extraData = serializeExtraData(node),
		children = serializedChildren,
	}
end

local function updateDumpButtonLabel()
	local menu = tes3ui.findMenu(ids.menu)
	if not menu then
		return
	end

	local button = menu:findChild(ids.dumpButton)
	if not button then
		return
	end

	local text = getDumpButtonText()
	local changed = false
	if button.text ~= text then
		button.text = text
		changed = true
	end
	if state.dumpButtonMinWidth and button.minWidth ~= state.dumpButtonMinWidth then
		button.minWidth = state.dumpButtonMinWidth
		changed = true
	end
	if changed then
		button.widget.textElement.absolutePosAlignX = 0.5
		menu:updateLayout()
	end
end

local function handleDumpModifierChange()
	updateDumpButtonLabel()
end

local function initializeDumpButtonWidth(menu, button)
	local originalText = button.text
	local maxWidth = button.width or 0

	for _, text in ipairs(getDumpButtonTexts()) do
		button.text = text
		menu:updateLayout()
		maxWidth = math.max(maxWidth, button.width or 0)
	end

	state.dumpButtonMinWidth = maxWidth
	button.text = originalText
	button.minWidth = maxWidth
	menu:updateLayout()
end

local function dumpSceneGraph()
	buildRootEntries()
	local entry = getCurrentRootEntry()
	if not entry or not entry.node then
		tes3.messageBox("Scene Inspector: no root is available to dump.")
		return
	end

	local dumpMode = getDumpMode()
	local selectedNode = state.selectedPath and state.nodeMap[state.selectedPath] or nil
	if dumpMode == "selected" and (not state.selectedPath or not selectedNode) then
		tes3.messageBox("Scene Inspector: select a node before copying the selected path.")
		return
	end

	local payload = {
		mod = modName,
		mode = dumpMode,
		rootLabel = entry.label,
		selectedPath = state.selectedPath,
		dumpPath = dumpPath,
		tree = dumpMode == "selected"
			and serializeSelectedLineage(state.selectedPath)
			or serializeNode(entry.node, entry.label, dumpMode, nil),
	}

	local encoded = json.encode(payload)
	if not encoded then
		tes3.messageBox("Scene Inspector: failed to encode scene dump.")
		return
	end

	local directory = "Data Files\\MWSE\\tmp"
	lfs.mkdir(directory)

	local file, errorMessage = io.open(dumpPath, "w+b")
	if not file then
		tes3.messageBox("Scene Inspector: failed to open dump file.\n%s", errorMessage or dumpPath)
		return
	end

	file:write(encoded)
	file:close()
	tes3.messageBox("Scene Inspector: wrote %s scene graph data to %s.", dumpMode, dumpPath)
end

getNodeCaption = function(node, slotIndex)
	local name = formatObjectName(node)
	local pieces = {
		name,
	}

	local reference = safeCall(safeIndex(node, "getGameReference"), node)
	if reference then
		local objectId = safeIndex(safeIndex(reference, "object"), "id")
		if objectId then
			table.insert(pieces, string.format("{%s}", objectId))
		end
	end

	if slotIndex then
		table.insert(pieces, string.format("#%d", slotIndex))
	end

	return table.concat(pieces, " ")
end

local function addValueRow(parent, label, value)
	local row = parent:createBlock({})
	row.widthProportional = 1.0
	row.autoHeight = true
	row.flowDirection = "left_to_right"

	local key = row:createLabel({ text = label .. ":" })
	key.minWidth = 150
	key.borderLeft = 8
	key.color = tes3ui.getPalette("header_color")

	local text = value
	if text == nil then
		text = "nil"
	elseif type(text) ~= "string" then
		text = tostring(text)
	end

	local valueLabel = row:createLabel({ text = text })
	valueLabel.wrapText = true
	valueLabel.widthProportional = 1.0
	valueLabel.color = { 0.85, 0.85, 0.85 }
end

local function addSectionHeader(parent, text)
	local header = parent:createLabel({ text = text })
	header.color = rttiAccentColor
	header.wrapText = true
	return header
end

local function updateRootLabel()
	local menu = tes3ui.findMenu(ids.menu)
	if not menu then
		return
	end

	local rootLabel = menu:findChild(ids.rootLabel)
	local previousButton = menu:findChild(ids.previousRootButton)
	local nextButton = menu:findChild(ids.nextRootButton)
	if not rootLabel then
		return
	end

	local entry = state.rootEntries[state.rootIndex]
	if entry then
		rootLabel.text = string.format("Root: %s", entry.label)
	else
		rootLabel.text = "Root: <unavailable>"
	end

	if #state.rootEntries == 0 then
		if previousButton then
			previousButton.text = "< Root"
		end
		if nextButton then
			nextButton.text = "Root >"
		end
		return
	end

	local previousIndex = state.rootIndex - 1
	if previousIndex < 1 then
		previousIndex = #state.rootEntries
	end

	local nextIndex = state.rootIndex + 1
	if nextIndex > #state.rootEntries then
		nextIndex = 1
	end

	if previousButton then
		previousButton.text = string.format("< %s", state.rootEntries[previousIndex].label)
	end
	if nextButton then
		nextButton.text = string.format("%s >", state.rootEntries[nextIndex].label)
	end
end

local function updateDetail(node)
	local menu = tes3ui.findMenu(ids.menu)
	if not menu then
		return
	end

	local pane = menu:findChild(ids.detailPane):getContentElement()
	pane:destroyChildren()
	pane.flowDirection = "top_to_bottom"
	pane.widthProportional = 1.0
	pane.autoHeight = true

	if not node then
		addValueRow(pane, "Selection", "Nothing selected")
		menu:updateLayout()
		return
	end

	sceneTypes.renderDetailPane(pane, node, {
		addSectionHeader = addSectionHeader,
		addValueRow = addValueRow,
	})

	menu:updateLayout()
end

local lastTarget = nil

buildRootEntries = function()
	local entries = {}

	local function tryAdd(label, resolver)
		local ok, node = pcall(resolver)
		if ok and node then
			table.insert(entries, {
				label = label,
				node = node,
			})
		end
	end

	tryAdd("World Root", function()
		return tes3.game.worldRoot
	end)
	tryAdd("UI Root", function()
		return tes3.worldController.menuController.mainRoot.sceneNode
	end)
	tryAdd("Player", function()
		return tes3.player and tes3.player.sceneNode
	end)
	lastTarget = tes3.getPlayerTarget() or lastTarget
	tryAdd("Target", function()
		return lastTarget and lastTarget:isValid() and lastTarget.sceneNode
	end)

	state.rootEntries = entries
	if state.rootIndex < 1 then
		state.rootIndex = 1
	elseif state.rootIndex > #entries then
		state.rootIndex = math.max(1, #entries)
	end
end

refreshTree = function()
	local menu = tes3ui.findMenu(ids.menu)
	if not menu then
		return
	end

	buildRootEntries()
	updateRootLabel()

	local pane = menu:findChild(ids.treePane):getContentElement()
	pane:destroyChildren()
	pane.flowDirection = "top_to_bottom"
	pane.widthProportional = 1.0
	pane.autoHeight = true
	state.nodeMap = {}

	local entry = state.rootEntries[state.rootIndex]
	if not entry then
		addValueRow(pane, "Scene Graph", "No roots are currently available.")
		updateDetail(nil)
		menu:updateLayout()
		return
	end

	local root = entry.node
	local rootPath = entry.label
	local selectedElement = nil
	if state.expanded[rootPath] == nil then
		state.expanded[rootPath] = true
	end

	local function ensureSelection()
		if not state.selectedPath or not state.nodeMap[state.selectedPath] then
			state.selectedPath = rootPath
		end
	end

	local function renderNode(node, path, depth, slotIndex)
		state.nodeMap[path] = node

		local line = pane:createBlock({})
		line.widthProportional = 1.0
		line.autoHeight = true
		line.flowDirection = "left_to_right"
		line.paddingLeft = depth * 16
		line.borderBottom = 2

		local children = collectChildren(node)
		local function toggleExpanded()
			if #children == 0 then
				return
			end
			state.expanded[path] = not (state.expanded[path] == true)
			refreshTree()
		end

		if #children > 0 then
			local expanded = state.expanded[path] == true
			local toggle = line:createLabel({ text = expanded and "-" or "+" })
			toggle.minWidth = 20
			toggle:register("mouseClick", toggleExpanded)
		else
			line:createLabel({ text = " " }).minWidth = 20
		end

		local typeLabel = line:createLabel({ text = string.format("[%s]", getRTTIName(node)) })
		typeLabel.color = rttiAccentColor
		typeLabel.autoWidth = true
		typeLabel.borderRight = 6
		if #children > 0 then
			typeLabel:register("mouseClick", toggleExpanded)
		end

		local select = line:createTextSelect({ text = getNodeCaption(node, slotIndex) })
		select.widthProportional = 1.0
		select.autoHeight = true
		if state.selectedPath == path then
			selectedElement = select
			select.widget.state = 2
			select.widget.idleActive = { 0.85, 0.78, 0.38 }
			select.widget.idleDisabled = { 0.85, 0.78, 0.38 }
		end
		select:register("mouseClick", function()
			state.selectedPath = path
			refreshTree()
		end)

		if #children > 0 and state.expanded[path] == true then
			for _, childEntry in ipairs(children) do
				renderNode(
					childEntry.node,
					string.format("%s/%d:%s", path, childEntry.index, tostring(childEntry.node)),
					depth + 1,
					childEntry.index
				)
			end
		end
	end

	renderNode(root, rootPath, 0, nil)
	ensureSelection()
	updateDetail(state.nodeMap[state.selectedPath])

	local treeScroll = menu:findChild(ids.treePane).widget
	if (treeScroll) then
		treeScroll:contentsChanged()
		treeScroll.element:updateLayout()
		menu:updateLayout()
		if selectedElement then
			treeScroll:scrollIntoView(selectedElement)
		end
	end
	local detailScroll = menu:findChild(ids.detailPane).widget
	if (detailScroll) then
		detailScroll:contentsChanged()
	end
	menu:updateLayout()
end

local function stepRoot(delta)
	buildRootEntries()
	if #state.rootEntries == 0 then
		tes3.messageBox("Scene Inspector: no scene roots are available right now.")
		return
	end

	state.rootIndex = state.rootIndex + delta
	if state.rootIndex < 1 then
		state.rootIndex = #state.rootEntries
	elseif state.rootIndex > #state.rootEntries then
		state.rootIndex = 1
	end
	state.selectedPath = nil
	refreshTree()
end

local function createInspector()
	local menu = tes3ui.createMenu({ id = ids.menu, dragFrame = true, loadable = true })
	menu.text = modName
	menu.minWidth = 780
	menu.minHeight = 640
	menu.flowDirection = "top_to_bottom"
	menu:loadMenuPosition()
	menu:registerBefore("destroy", leaveInspectorMenuMode)
	menu:register("update", updateDumpButtonLabel)

	local controlsTop = menu:createBlock({})
	controlsTop.widthProportional = 1.0
	controlsTop.autoHeight = true
	controlsTop.flowDirection = "left_to_right"
	controlsTop.childAlignY = 0.5
	controlsTop.borderBottom = 8

	local previousButton = controlsTop:createButton({ id = ids.previousRootButton, text = "< Root" })
	previousButton:register("mouseClick", function()
		stepRoot(-1)
	end)

	local rootLabel = controlsTop:createLabel({ id = ids.rootLabel, text = "Root: <unavailable>" })
	rootLabel.absolutePosAlignX = 0.5
	rootLabel.absolutePosAlignY = 0.5
	rootLabel.widthProportional = 1.0
	rootLabel.color = tes3ui.getPalette("header_color")

	local nextButton = controlsTop:createButton({ id = ids.nextRootButton, text = "Root >" })
	nextButton.absolutePosAlignX = 1.0
	nextButton.absolutePosAlignY = 0.5
	nextButton:register("mouseClick", function()
		stepRoot(1)
	end)

	local content = menu:createBlock({})
	content.widthProportional = 1.0
	content.heightProportional = 1.0
	content.flowDirection = "top_to_bottom"

	local treePane = content:createVerticalScrollPane({ id = ids.treePane })
	treePane.widthProportional = 1.0
	treePane.heightProportional = (0.6)*2
	treePane.paddingAllSides = 4
	treePane.borderBottom = 6

	local detailPane = content:createVerticalScrollPane({ id = ids.detailPane })
	detailPane.widthProportional = 1.0
	detailPane.heightProportional = (0.4)*2
	detailPane.paddingAllSides = 4

	local controlsBottom = menu:createBlock({})
	controlsBottom.widthProportional = 1.0
	controlsBottom.autoHeight = true
	controlsBottom.flowDirection = "left_to_right"
	controlsBottom.childAlignY = 0.5
	controlsBottom.childAlignX = 1.0

	local refreshButton = controlsBottom:createButton({ text = "Refresh Snapshot" })
	refreshButton:register("mouseClick", function()
		refreshTree()
	end)

	local dumpButton = controlsBottom:createButton({ id = ids.dumpButton, text = getDumpButtonText() })
	dumpButton.borderLeft = 12
	dumpButton.childAlignX = 0.5
	dumpButton:register("mouseClick", dumpSceneGraph)

	local closeButton = controlsBottom:createButton({ text = "Close" })
	closeButton.borderLeft = 12
	closeButton:register("mouseClick", function()
		menu:destroy()
	end)

	menu:updateLayout()
	content:updateLayout()
	initializeDumpButtonWidth(menu, dumpButton)
end

local function toggleInspector()
	local menu = tes3ui.findMenu(ids.menu)
	if menu then
		menu:destroy()
		return
	end

	createInspector()
	tes3ui.enterMenuMode(ids.menu)
	refreshTree()
end

--- @param e keyEventData
local function init()
	ids.menu = tes3ui.registerID("SceneInspector:Menu")
	ids.rootLabel = tes3ui.registerID("SceneInspector:RootLabel")
	ids.previousRootButton = tes3ui.registerID("SceneInspector:PreviousRootButton")
	ids.nextRootButton = tes3ui.registerID("SceneInspector:NextRootButton")
	ids.treePane = tes3ui.registerID("SceneInspector:TreePane")
	ids.detailPane = tes3ui.registerID("SceneInspector:DetailPane")
	ids.dumpButton = tes3ui.registerID("SceneInspector:DumpButton")

	event.register(tes3.event.keyDown, toggleInspector, { filter = tes3.scanCode.F3 })
	event.register(tes3.event.key, handleDumpModifierChange, { filter = tes3.scanCode.leftShift })
	event.register(tes3.event.key, handleDumpModifierChange, { filter = tes3.scanCode.rightShift })
	event.register(tes3.event.key, handleDumpModifierChange, { filter = tes3.scanCode.leftAlt })
	event.register(tes3.event.key, handleDumpModifierChange, { filter = tes3.scanCode.rightAlt })
	event.register(tes3.event.mouseButtonDown, raySelectAtCursor)
end

local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder({})
	pane.widthProportional = 1.0
	pane.heightProportional = 1.0
	pane.paddingAllSides = 12
	pane.flowDirection = "top_to_bottom"

	local header = pane:createLabel({ text = modName })
	header.color = tes3ui.getPalette("header_color")
	header.borderBottom = 10

	local body = pane:createLabel({
		text = "Press F3 to open the scene graph snapshot inspector.\n\nAvailable roots include the player, current target, world roots, cursor node, and weather scene roots when they exist.",
	})
	body.wrapText = true
	body.widthProportional = 1.0
end

local function registerModConfig()
	mwse.registerModConfig(modName, modConfig)
end

event.register(tes3.event.initialized, init)
event.register(tes3.event.modConfigReady, registerModConfig)
