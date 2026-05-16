local types = {}

local function safeIndex(value, key)
	local ok, result = pcall(function()
		return value[key]
	end)
	if not ok then
		return nil
	end
	return result
end

local function getRTTIName(object)
	local rtti = safeIndex(object, "RTTI") or safeIndex(object, "runTimeTypeInformation")
	local name = safeIndex(rtti, "name")
	return name or "<unknown>"
end

local function formatNumber(value)
	if type(value) ~= "number" then
		return tostring(value)
	end

	if value == math.floor(value) then
		return tostring(value)
	end

	return string.format("%.4f", value):gsub("0+$", ""):gsub("%.$", "")
end

local function formatVector3(value)
	if not value then
		return "nil"
	end

	local x = safeIndex(value, "x")
	local y = safeIndex(value, "y")
	local z = safeIndex(value, "z")
	if x ~= nil and y ~= nil and z ~= nil then
		return string.format("(%s, %s, %s)", formatNumber(x), formatNumber(y), formatNumber(z))
	end

	return tostring(value)
end

local function formatRotation(value)
	if not value then
		return "nil"
	end

	local ok, text = pcall(tostring, value)
	return ok and text or "<rotation>"
end

local function formatTransform(value)
	if not value then
		return "nil"
	end

	local translation = formatVector3(safeIndex(value, "translation"))
	local scale = formatNumber(safeIndex(value, "scale"))
	local rotation = formatRotation(safeIndex(value, "rotation"))
	return string.format("translation=%s\nscale=%s\nrotation=%s", translation, scale, rotation)
end

local function formatValue(value)
	local valueType = type(value)
	if value == nil or valueType == "number" or valueType == "boolean" or valueType == "string" then
		return value
	end

	return tostring(value)
end

local function formatObjectSummary(value)
	if not value then
		return "nil"
	end

	local name = safeIndex(value, "name")
	if name == nil or name == "" then
		name = "<unnamed>"
	end

	local rtti = getRTTIName(value)
	return string.format("%s [%s] @ %s", name, rtti, tostring(value))
end

local function formatListSummary(value)
	if type(value) ~= "table" then
		return formatValue(value)
	end

	local count = 0
	for key, entry in pairs(value) do
		if type(key) == "number" and entry ~= nil then
			count = count + 1
		end
	end

	return string.format("%d entries", count)
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

local formatters = {
	boolean = function(value)
		if value == nil then
			return "nil"
		end
		return tostring(value)
	end,
	list = formatListSummary,
	number = formatNumber,
	object = formatObjectSummary,
	rotation = formatRotation,
	text = function(value)
		if value == nil or value == "" then
			return "<unnamed>"
		end
		return tostring(value)
	end,
	transform = formatTransform,
	value = formatValue,
	vector3 = formatVector3,
}

local function typeLabel(typeName)
	return (typeName:gsub("^ni", "Ni", 1))
end

local function normalizeTypeName(typeName)
	if type(typeName) ~= "string" then
		return nil
	end

	return (typeName:sub(1, 1):lower() .. typeName:sub(2))
end

local function color(r, g, b)
	return { r, g, b }
end

types.definitions = {
	niObject = {
		label = "NiObject",
		fields = {
			{ key = "refCount", label = "Ref Count", format = "number" },
		},
	},
	niObjectNET = {
		label = "NiObjectNET",
		fields = {
			{ key = "name", label = "Name", format = "text" },
			{ key = "controller", label = "Controller", render = "controllerLink" },
			{ key = "extraData", label = "Extra Data", format = "object" },
		},
	},
	niNode = {
		label = "NiNode",
		color = color(0.55, 0.7, 0.85),
		fields = {
			{ key = "children", label = "Children", format = "list" },
			{ key = "effectList", label = "Effect List", format = "object" },
		},
	},
	niAVObject = {
		label = "NiAVObject",
		fields = {
			{ key = "appCulled", label = "App Culled", format = "boolean" },
			{ key = "flags", label = "Flags", format = "number" },
			{ key = "parent", label = "Parent", format = "object" },
			{ key = "properties", label = "Properties", render = "propertyLinks" },
			{ key = "rotation", label = "Rotation", format = "rotation" },
			{ key = "scale", label = "Scale", format = "number" },
			{ key = "translation", label = "Translation", format = "vector3" },
			{ key = "velocity", label = "Velocity", format = "vector3" },
			{ key = "worldBoundOrigin", label = "World Bound Origin", format = "vector3" },
			{ key = "worldBoundRadius", label = "World Bound Radius", format = "number" },
			{ key = "worldTransform", label = "World Transform", format = "transform" },
		},
	},
	niProperty = {
		label = "NiProperty",
		color = color(0.35, 0.8, 0.45),
		fields = {
			{ key = "propertyFlags", label = "Property Flags", format = "number" },
			{ key = "type", label = "Type", format = "value" },
		},
	},
	niGeometry = {
		label = "NiGeometry",
		color = color(0.66, 0.45, 0.9),
		fields = {},
	},
	niTimeController = {
		label = "NiTimeController",
		color = color(0.9, 0.3, 0.3),
		fields = {},
	},
}

local function buildLineage(object)
	local lineage = {}
	local seen = {}
	local rtti = safeIndex(object, "RTTI") or safeIndex(object, "runTimeTypeInformation")
	local guard = 32

	while rtti and guard > 0 do
		local name = safeIndex(rtti, "name")
		if not name or seen[name] then
			break
		end

		table.insert(lineage, 1, name)
		seen[name] = true
		rtti = safeIndex(rtti, "parent")
		guard = guard - 1
	end

	return lineage
end

local function formatFieldValue(field, value)
	local formatter = field.format
	if type(formatter) == "function" then
		return formatter(value, field)
	end

	local handler = formatters[formatter or "value"] or formatters.value
	return handler(value, field)
end

function types.getLineage(object)
	return buildLineage(object)
end

function types.getSections(object)
	local sections = {}

	for _, typeName in ipairs(buildLineage(object)) do
		local definition = types.definitions[normalizeTypeName(typeName)]
		if definition and definition.fields then
			local rows = {}
			for _, field in ipairs(definition.fields) do
				local value = safeIndex(object, field.key)
				if field.render == "propertyLinks" then
					value = collectPropertyList(value)
				end
				table.insert(rows, {
					label = field.label or field.key,
					value = formatFieldValue(field, value),
					rawValue = value,
					field = field,
				})
			end

			if #rows > 0 then
				table.insert(sections, {
					label = definition.label or typeLabel(typeName),
					rows = rows,
				})
			end
		end
	end

	return sections
end

function types.getColor(object)
	for _, typeName in ipairs(buildLineage(object)) do
		local definition = types.definitions[normalizeTypeName(typeName)]
		if definition and definition.color then
			return definition.color
		end
	end

	return nil
end

function types.renderDetailPane(pane, object, helpers)
	helpers = helpers or {}
	local addSectionHeader = helpers.addSectionHeader
	local addValueRow = helpers.addValueRow
	local addLinkRow = helpers.addLinkRow
	local addLinkListRow = helpers.addLinkListRow
	local focusObject = helpers.focusObject

	if type(addSectionHeader) ~= "function" or type(addValueRow) ~= "function" then
		error("Scene Inspector types.lua requires addSectionHeader and addValueRow helpers.")
	end

	local sections = types.getSections(object)
	if #sections == 0 then
		addValueRow(pane, "Type", getRTTIName(object))
		addValueRow(pane, "Pointer", tostring(object))
		return
	end

	for i, section in ipairs(sections) do
		local header = addSectionHeader(pane, section.label)
		for _, row in ipairs(section.rows) do
			local field = row.field or {}
			if field.render == "controllerLink" then
				if type(addLinkRow) ~= "function" or type(focusObject) ~= "function" then
					error("Scene Inspector types.lua requires addLinkRow and focusObject helpers for controller links.")
				end

				local controller = row.rawValue
				if controller then
					local controllerName = safeIndex(controller, "name")
					if controllerName == nil or controllerName == "" then
						controllerName = "<unnamed>"
					end

					addLinkRow(
						pane,
						row.label,
						string.format("%s (%s)", controllerName, getRTTIName(controller)),
						function()
							focusObject(controller)
						end
					)
				else
					addValueRow(pane, row.label, "None")
				end
			elseif field.render == "propertyLinks" then
				if type(addLinkListRow) ~= "function" or type(focusObject) ~= "function" then
					error("Scene Inspector types.lua requires addLinkListRow and focusObject helpers for property links.")
				end

				local items = {}
				for _, property in ipairs(row.rawValue or {}) do
					table.insert(items, {
						text = getRTTIName(property),
						value = property,
					})
				end

				addLinkListRow(pane, row.label, items, function(property)
					focusObject(property)
				end)
			else
				addValueRow(pane, row.label, row.value)
			end
		end
	end
end

return types
