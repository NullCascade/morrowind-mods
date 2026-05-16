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
			{ key = "controller", label = "Controller", format = "object" },
			{ key = "extraData", label = "Extra Data", format = "object" },
		},
	},
	niAVObject = {
		label = "NiAVObject",
		fields = {
			{ key = "alphaProperty", label = "Alpha Property", format = "object" },
			{ key = "appCulled", label = "App Culled", format = "boolean" },
			{ key = "flags", label = "Flags", format = "number" },
			{ key = "fogProperty", label = "Fog Property", format = "object" },
			{ key = "materialProperty", label = "Material Property", format = "object" },
			{ key = "parent", label = "Parent", format = "object" },
			{ key = "properties", label = "Properties", format = "object" },
			{ key = "rotation", label = "Rotation", format = "rotation" },
			{ key = "scale", label = "Scale", format = "number" },
			{ key = "stencilProperty", label = "Stencil Property", format = "object" },
			{ key = "texturingProperty", label = "Texturing Property", format = "object" },
			{ key = "translation", label = "Translation", format = "vector3" },
			{ key = "velocity", label = "Velocity", format = "vector3" },
			{ key = "vertexColorProperty", label = "Vertex Color Property", format = "object" },
			{ key = "worldBoundOrigin", label = "World Bound Origin", format = "vector3" },
			{ key = "worldBoundRadius", label = "World Bound Radius", format = "number" },
			{ key = "worldTransform", label = "World Transform", format = "transform" },
			{ key = "zBufferProperty", label = "Z Buffer Property", format = "object" },
		},
	},
	niNode = {
		label = "NiNode",
		fields = {
			{ key = "children", label = "Children", format = "list" },
			{ key = "effectList", label = "Effect List", format = "object" },
		},
	},
	niProperty = {
		label = "NiProperty",
		fields = {
			{ key = "propertyFlags", label = "Property Flags", format = "number" },
			{ key = "type", label = "Type", format = "value" },
		},
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
				table.insert(rows, {
					label = field.label or field.key,
					value = formatFieldValue(field, value),
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

function types.renderDetailPane(pane, object, helpers)
	helpers = helpers or {}
	local addSectionHeader = helpers.addSectionHeader
	local addValueRow = helpers.addValueRow

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
		if i > 1 then
			header.borderTop = 4
		end
		for _, row in ipairs(section.rows) do
			addValueRow(pane, row.label, row.value)
		end
	end
end

return types
