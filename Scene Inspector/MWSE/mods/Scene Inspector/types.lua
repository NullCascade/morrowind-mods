local types = {}

---@class SceneInspectorLinkItem
---@field text string
---@field value SceneInspectorLinkValue

---@alias SceneInspectorLinkValue niObject|SceneInspectorTexturingPropertyMap

---@class SceneInspectorTexturingPropertyMap
---@field texture niRenderedTexture|niSourceTexture|niTexture|nil
---@field clampMode ni.texturingPropertyClampMode|nil
---@field filterMode ni.texturingPropertyFilterMode|nil
---@field texCoordSet integer|nil

---@class SceneInspectorDetailHelpers
---@field addSectionHeader nil|fun(parent: tes3uiElement, text: string): tes3uiElement|nil
---@field addValueRow nil|fun(parent: tes3uiElement, label: string, value: string|number|boolean|nil): tes3uiElement|nil
---@field addLinkRow nil|fun(parent: tes3uiElement, label: string, text: string, onClick: fun()): tes3uiElement|nil
---@field addLinkListRow nil|fun(parent: tes3uiElement, label: string, items: SceneInspectorLinkItem[], onClick: fun(value: SceneInspectorLinkValue)): tes3uiElement|nil
---@field showMapPopup nil|fun(map: SceneInspectorTexturingPropertyMap, title: string|nil): nil
---@field focusObject nil|fun(targetNode: niObject): boolean|nil

--- @generic T
--- @param value T
--- @param key string|integer
--- @return any
local function safeIndex(value, key)
	local ok, result = pcall(function()
		return value[key]
	end)
	if not ok then
		return nil
	end
	return result
end

--- @param object niObject
--- @return string
local function getRTTIName(object)
	local rtti = safeIndex(object, "RTTI") or safeIndex(object, "runTimeTypeInformation")
	local name = safeIndex(rtti, "name")
	return name or "<unknown>"
end

--- @param value nil|boolean|number|string|table|userdata
--- @return string
local function formatNumber(value)
	if type(value) ~= "number" then
		return tostring(value)
	end

	if value == math.floor(value) then
		return tostring(value)
	end

	local result = string.format("%.4f", value):gsub("0+$", ""):gsub("%.$", "")
	return result
end

--- @param value tes3vector3|table|nil
--- @return string
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

--- @param value tes3vector4|table|nil
--- @return string
local function formatVector4(value)
	if not value then
		return "nil"
	end

	local x = safeIndex(value, "x")
	local y = safeIndex(value, "y")
	local z = safeIndex(value, "z")
	local w = safeIndex(value, "w")
	if x ~= nil and y ~= nil and z ~= nil and w ~= nil then
		return string.format("(%s, %s, %s, %s)", formatNumber(x), formatNumber(y), formatNumber(z), formatNumber(w))
	end

	return tostring(value)
end

--- @param value table|userdata|nil
--- @return string
local function formatRotation(value)
	if not value then
		return "nil"
	end

	local ok, text = pcall(tostring, value)
	return ok and text or "<rotation>"
end

--- @param value tes3transform|table|userdata|nil
--- @return string
local function formatTransform(value)
	if not value then
		return "nil"
	end

	local translation = formatVector3(safeIndex(value, "translation"))
	local scale = formatNumber(safeIndex(value, "scale"))
	local rotation = formatRotation(safeIndex(value, "rotation"))
	return string.format("translation=%s\nscale=%s\nrotation=%s", translation, scale, rotation)
end

--- @param value niColor|niColorA|table|userdata|nil
--- @return string
local function formatColor(value)
	if not value then
		return "nil"
	end

	local r = safeIndex(value, "r") or safeIndex(value, 1)
	local g = safeIndex(value, "g") or safeIndex(value, 2)
	local b = safeIndex(value, "b") or safeIndex(value, 3)
	local a = safeIndex(value, "a") or safeIndex(value, 4)

	if r ~= nil and g ~= nil and b ~= nil then
		if a ~= nil then
			return string.format("(%s, %s, %s, %s)", formatNumber(r), formatNumber(g), formatNumber(b), formatNumber(a))
		end
		return string.format("(%s, %s, %s)", formatNumber(r), formatNumber(g), formatNumber(b))
	end

	return tostring(value)
end

--- @param value nil|boolean|number|string|table|userdata
--- @return nil|boolean|number|string
local function formatValue(value)
	local valueType = type(value)
	if value == nil or valueType == "number" or valueType == "boolean" or valueType == "string" then
		return value
	end

	return tostring(value)
end

--- @param head niProperty|nil
--- @param limit? integer
--- @return niProperty[]
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

--- @param head niDynamicEffect|nil
--- @param limit? integer
--- @return niDynamicEffect[]
local function collectEffectList(head, limit)
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
		local effect = safeIndex(current, "data")
		if effect then
			table.insert(results, effect)
		end
		current = safeIndex(current, "next")
		remaining = remaining - 1
	end
	return results
end

--- @param head niObject|table|nil
--- @param limit? integer
--- @return niObject[]
local function collectObjectList(head, limit)
	local results = {}
	if type(head) ~= "table" then
		return results
	end

	local linked = safeIndex(head, "next") ~= nil or safeIndex(head, "data") ~= nil
	if linked then
		local current = head
		local seen = {}
		local remaining = limit or 64
		while current and remaining > 0 do
			local key = tostring(current)
			if seen[key] then
				break
			end
			seen[key] = true
			local object = safeIndex(current, "data") or current
			if object then
				table.insert(results, object)
			end
			current = safeIndex(current, "next")
			remaining = remaining - 1
		end
		return results
	end

	local remaining = limit or 64
	for key, entry in pairs(head) do
		if remaining <= 0 then
			break
		end
		if type(key) == "number" and entry ~= nil then
			table.insert(results, entry)
			remaining = remaining - 1
		end
	end

	return results
end

--- @param value niObject|nil
--- @return string
local function formatObjectSummary(value)
	if not value then
		return "nil"
	end

	local name = safeIndex(value, "name")
	if name == nil or name == "" then
		name = "<unnamed>"
	end

	local rtti = getRTTIName(value)
	return string.format("%s (%s)", name, rtti)
end

--- @param value SceneInspectorTexturingPropertyMap|nil
--- @return string
local function formatTexturingPropertyMapSummary(value)
	if not value then
		return "None"
	end

	local texture = safeIndex(value, "texture")
	local textureSummary = texture and formatObjectSummary(texture) or "None"
	local clampMode = formatValue(safeIndex(value, "clampMode")) or "nil"
	local filterMode = formatValue(safeIndex(value, "filterMode")) or "nil"
	local texCoordSet = formatValue(safeIndex(value, "texCoordSet")) or "nil"
	return string.format("%s, clamp=%s, filter=%s, set=%s", textureSummary, clampMode, filterMode, texCoordSet)
end

--- @param value table|nil
--- @return string
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

--- @param value table|nil
--- @return string
local function formatObjectListSummary(value)
	return formatListSummary(value)
end

--- @param head SceneInspectorTexturingPropertyMap[]|table|nil
--- @param limit? integer
--- @return SceneInspectorTexturingPropertyMap[]
local function collectMapList(head, limit)
	local results = {}
	if type(head) ~= "table" then
		return results
	end

	local linked = safeIndex(head, "next") ~= nil or safeIndex(head, "data") ~= nil
	if linked then
		local current = head
		local seen = {}
		local remaining = limit or 64
		while current and remaining > 0 do
			local key = tostring(current)
			if seen[key] then
				break
			end
			seen[key] = true
			local map = safeIndex(current, "data") or current
			if map then
				table.insert(results, map)
			end
			current = safeIndex(current, "next")
			remaining = remaining - 1
		end
		return results
	end

	local remaining = limit or 64
	for key, entry in pairs(head) do
		if remaining <= 0 then
			break
		end
		if type(key) == "number" and entry ~= nil then
			table.insert(results, entry)
			remaining = remaining - 1
		end
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
	color = formatColor,
	list = formatListSummary,
	number = formatNumber,
	object = formatObjectSummary,
	objectList = formatObjectListSummary,
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
	vector4 = formatVector4,
}

--- @param typeName string
--- @return string
local function typeLabel(typeName)
	return (typeName:gsub("^ni", "Ni", 1))
end

--- @param typeName string
--- @return string|nil
local function normalizeTypeName(typeName)
	if type(typeName) ~= "string" then
		return nil
	end

	return (typeName:sub(1, 1):lower() .. typeName:sub(2))
end

--- @param r number
--- @param g number
--- @param b number
--- @return number[]
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
			{ key = "effectList", label = "Effect List", render = "effectLinks" },
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
	niAlphaProperty = {
		label = "NiAlphaProperty",
		fields = {
			{ key = "alphaTestRef", label = "Alpha Test Ref", format = "number" },
		},
	},
	niFogProperty = {
		label = "NiFogProperty",
		fields = {
			{ key = "color", label = "Color", format = "color" },
			{ key = "density", label = "Density", format = "number" },
		},
	},
	niMaterialProperty = {
		label = "NiMaterialProperty",
		fields = {
			{ key = "alpha", label = "Alpha", format = "number" },
			{ key = "ambient", label = "Ambient", format = "color" },
			{ key = "diffuse", label = "Diffuse", format = "color" },
			{ key = "emissive", label = "Emissive", format = "color" },
			{ key = "shininess", label = "Shininess", format = "number" },
			{ key = "specular", label = "Specular", format = "color" },
		},
	},
	niStencilProperty = {
		label = "NiStencilProperty",
		fields = {
			{ key = "drawMode", label = "Draw Mode", format = "value" },
			{ key = "enabled", label = "Enabled", format = "boolean" },
			{ key = "failAction", label = "Fail Action", format = "value" },
			{ key = "mask", label = "Mask", format = "number" },
			{ key = "passAction", label = "Pass Action", format = "value" },
			{ key = "reference", label = "Reference", format = "number" },
			{ key = "testFunc", label = "Test Function", format = "value" },
			{ key = "zFailAction", label = "Z Fail Action", format = "value" },
		},
	},
	niTexturingProperty = {
		label = "NiTexturingProperty",
		fields = {
			{ key = "applyMode", label = "Apply Mode", format = "value" },
			{ key = "baseMap", label = "Base Map", render = "mapLink" },
			{ key = "bumpMap", label = "Bump Map", render = "mapLink" },
			{ key = "canAddDecal", label = "Can Add Decal", format = "boolean" },
			{ key = "darkMap", label = "Dark Map", render = "mapLink" },
			{ key = "decalCount", label = "Decal Count", format = "number" },
			{ key = "detailMap", label = "Detail Map", render = "mapLink" },
			{ key = "glossMap", label = "Gloss Map", render = "mapLink" },
			{ key = "glowMap", label = "Glow Map", render = "mapLink" },
			{ key = "maps", label = "Maps", render = "mapLinks" },
		},
	},
	niVertexColorProperty = {
		label = "NiVertexColorProperty",
		fields = {
			{ key = "lighting", label = "Lighting", format = "value" },
			{ key = "source", label = "Source", format = "value" },
		},
	},
	niZBufferProperty = {
		label = "NiZBufferProperty",
		fields = {
			{ key = "testFunction", label = "Test Function", format = "value" },
		},
	},
	niGeometry = {
		label = "NiGeometry",
		color = color(0.66, 0.45, 0.9),
		fields = {},
	},
	niGeometryData = {
		label = "NiGeometryData",
		color = color(0.66, 0.45, 0.9),
		fields = {
			{ key = "activeVertices", label = "Active Vertices", format = "list" },
			{ key = "bounds", label = "Bounds", format = "object" },
			{ key = "colors", label = "Colors", format = "list" },
			{ key = "normals", label = "Normals", format = "list" },
			{ key = "texCoords", label = "Tex Coords", format = "list" },
			{ key = "textures", label = "Textures", format = "list" },
			{ key = "textureSets", label = "Texture Sets", format = "number" },
			{ key = "uniqueID", label = "Unique ID", format = "number" },
			{ key = "vertexCount", label = "Vertex Count", format = "number" },
			{ key = "vertices", label = "Vertices", format = "list" },
		},
	},
	niTriBasedGeometryData = {
		label = "NiTriBasedGeometryData",
		color = color(0.66, 0.45, 0.9),
		fields = {
			{ key = "activeTriangleCount", label = "Active Triangle Count", format = "number" },
			{ key = "triangleCount", label = "Triangle Count", format = "number" },
		},
	},
	niTriShapeData = {
		label = "NiTriShapeData",
		color = color(0.66, 0.45, 0.9),
		fields = {
			{ key = "triangles", label = "Triangles", format = "list" },
		},
	},
	niTriShape = {
		label = "NiTriShape",
		color = color(0.66, 0.45, 0.9),
		fields = {
			{ key = "data", label = "Data", format = "object" },
			{ key = "normals", label = "Normals", format = "list" },
			{ key = "skinInstance", label = "Skin Instance", format = "object" },
			{ key = "vertices", label = "Vertices", format = "list" },
		},
	},
	niBound = {
		label = "NiBound",
		fields = {
			{ key = "center", label = "Center", format = "vector3" },
			{ key = "radius", label = "Radius", format = "number" },
		},
	},
	niSkinInstance = {
		label = "NiSkinInstance",
		fields = {
			{ key = "bones", label = "Bones", render = "objectLinks" },
			{ key = "data", label = "Data", format = "object" },
			{ key = "root", label = "Root", format = "object" },
		},
	},
	niSkinData = {
		label = "NiSkinData",
		fields = {
			{ key = "boneData", label = "Bone Data", format = "list" },
			{ key = "partition", label = "Partition", format = "object" },
			{ key = "transform", label = "Transform", format = "transform" },
		},
	},
	niDynamicEffect = {
		label = "NiDynamicEffect",
		color = color(0.95, 0.82, 0.25),
		fields = {
			{ key = "affectedNodes", label = "Affected Nodes", format = "list" },
			{ key = "enabled", label = "Enabled", format = "boolean" },
			{ key = "type", label = "Type", format = "value" },
		},
	},
	niLight = {
		label = "NiLight",
		fields = {
			{ key = "ambient", label = "Ambient", format = "color" },
			{ key = "diffuse", label = "Diffuse", format = "color" },
			{ key = "dimmer", label = "Dimmer", format = "number" },
			{ key = "specular", label = "Specular", format = "color" },
		},
	},
	niDirectionalLight = {
		label = "NiDirectionalLight",
		fields = {
			{ key = "direction", label = "Direction", format = "vector3" },
		},
	},
	niPointLight = {
		label = "NiPointLight",
		fields = {
			{ key = "constantAttenuation", label = "Constant Attenuation", format = "number" },
			{ key = "linearAttenuation", label = "Linear Attenuation", format = "number" },
			{ key = "quadraticAttenuation", label = "Quadratic Attenuation", format = "number" },
		},
	},
	niSpotLight = {
		label = "NiSpotLight",
		fields = {
			{ key = "direction", label = "Direction", format = "vector3" },
			{ key = "spotAngle", label = "Spot Angle", format = "number" },
			{ key = "spotExponent", label = "Spot Exponent", format = "number" },
		},
	},
	niTextureEffect = {
		label = "NiTextureEffect",
		fields = {
			{ key = "sourceTexture", label = "Source Texture", format = "object" },
		},
	},
	niTimeController = {
		label = "NiTimeController",
		color = color(0.9, 0.3, 0.3),
		fields = {
			{ key = "active", label = "Active", format = "boolean" },
			{ key = "animTimingType", label = "Anim Timing Type", format = "value" },
			{ key = "cycleType", label = "Cycle Type", format = "value" },
			{ key = "frequency", label = "Frequency", format = "number" },
			{ key = "highKeyFrame", label = "High Key Frame", format = "number" },
			{ key = "lastScaledTime", label = "Last Scaled Time", format = "number" },
			{ key = "lastTime", label = "Last Time", format = "number" },
			{ key = "lowKeyFrame", label = "Low Key Frame", format = "number" },
			{ key = "nextController", label = "Next Controller", format = "object" },
			{ key = "phase", label = "Phase", format = "number" },
			{ key = "startTime", label = "Start Time", format = "number" },
			{ key = "target", label = "Target", format = "object" },
		},
	},
	niKeyframeController = {
		label = "NiKeyframeController",
		color = color(0.9, 0.3, 0.3),
		fields = {
			{ key = "data", label = "Data", format = "object" },
			{ key = "lastUsedPositionIndex", label = "Last Used Position Index", format = "number" },
			{ key = "lastUsedRotationIndex", label = "Last Used Rotation Index", format = "number" },
			{ key = "lastUsedScaleIndex", label = "Last Used Scale Index", format = "number" },
		},
	},
	niLookAtController = {
		label = "NiLookAtController",
		color = color(0.9, 0.3, 0.3),
		fields = {
			{ key = "axis", label = "Axis", format = "value" },
			{ key = "flip", label = "Flip", format = "boolean" },
			{ key = "lookAt", label = "Look At", format = "object" },
		},
	},
	niPathController = {
		label = "NiPathController",
		color = color(0.9, 0.3, 0.3),
		fields = {
			{ key = "allowFlip", label = "Allow Flip", format = "boolean" },
			{ key = "bank", label = "Bank", format = "boolean" },
			{ key = "bankDirection", label = "Bank Direction", format = "number" },
			{ key = "constantVelocity", label = "Constant Velocity", format = "boolean" },
			{ key = "flipFollowAxis", label = "Flip Follow Axis", format = "boolean" },
			{ key = "follow", label = "Follow", format = "boolean" },
			{ key = "followAxis", label = "Follow Axis", format = "number" },
			{ key = "lastUsedPathIndex", label = "Last Used Path Index", format = "number" },
			{ key = "lastUsedPercentIndex", label = "Last Used Percent Index", format = "number" },
			{ key = "maxBankAngle", label = "Max Bank Angle", format = "number" },
			{ key = "openCurve", label = "Open Curve", format = "boolean" },
			{ key = "pathData", label = "Path Data", format = "object" },
			{ key = "percentData", label = "Percent Data", format = "object" },
			{ key = "smoothing", label = "Smoothing", format = "number" },
			{ key = "totalLength", label = "Total Length", format = "number" },
		},
	},
	niParticleModifier = {
		label = "NiParticleModifier",
		fields = {
			{ key = "controller", label = "Controller", format = "object" },
			{ key = "next", label = "Next", format = "object" },
		},
	},
	niParticleColorModifier = {
		label = "NiParticleColorModifier",
		fields = {
			{ key = "colorData", label = "Color Data", format = "object" },
		},
	},
	niParticleCollider = {
		label = "NiParticleCollider",
		fields = {
			{ key = "collisionPoint", label = "Collision Point", format = "vector3" },
			{ key = "collisionTime", label = "Collision Time", format = "number" },
			{ key = "dieOnCollide", label = "Die On Collide", format = "boolean" },
			{ key = "restitution", label = "Restitution", format = "number" },
			{ key = "spawnOnCollide", label = "Spawn On Collide", format = "boolean" },
		},
	},
	niGravity = {
		label = "NiGravity",
		fields = {
			{ key = "decay", label = "Decay", format = "number" },
			{ key = "direction", label = "Direction", format = "vector3" },
			{ key = "force", label = "Force", format = "number" },
			{ key = "forceType", label = "Force Type", format = "value" },
			{ key = "position", label = "Position", format = "vector3" },
		},
	},
	niParticleBomb = {
		label = "NiParticleBomb",
		fields = {
			{ key = "decay", label = "Decay", format = "number" },
			{ key = "decayType", label = "Decay Type", format = "value" },
			{ key = "deltaV", label = "Delta V", format = "number" },
			{ key = "direction", label = "Direction", format = "vector3" },
			{ key = "duration", label = "Duration", format = "number" },
			{ key = "position", label = "Position", format = "vector3" },
			{ key = "start", label = "Start", format = "number" },
			{ key = "symmetryType", label = "Symmetry Type", format = "value" },
		},
	},
	niParticleGrowFade = {
		label = "NiParticleGrowFade",
		fields = {
			{ key = "fade", label = "Fade", format = "number" },
			{ key = "grow", label = "Grow", format = "number" },
		},
	},
	niParticleRotation = {
		label = "NiParticleRotation",
		fields = {
			{ key = "initialAxis", label = "Initial Axis", format = "vector3" },
			{ key = "randomInitialAxis", label = "Random Initial Axis", format = "boolean" },
			{ key = "rotationSpeed", label = "Rotation Speed", format = "number" },
		},
	},
	niPlanarCollider = {
		label = "NiPlanarCollider",
		fields = {
			{ key = "height", label = "Height", format = "number" },
			{ key = "planeEquation", label = "Plane Equation", format = "vector4" },
			{ key = "position", label = "Position", format = "vector3" },
			{ key = "width", label = "Width", format = "number" },
			{ key = "xAxis", label = "X Axis", format = "vector3" },
			{ key = "yAxis", label = "Y Axis", format = "vector3" },
		},
	},
	niSphericalCollider = {
		label = "NiSphericalCollider",
		fields = {
			{ key = "position", label = "Position", format = "vector3" },
			{ key = "radius", label = "Radius", format = "number" },
		},
	},
	niParticleSystemController = {
		label = "NiParticleSystemController",
		color = color(0.9, 0.3, 0.3),
		fields = {
			{ key = "activeParticleCount", label = "Active Particle Count", format = "number" },
			{ key = "birthRate", label = "Birth Rate", format = "number" },
			{ key = "currentParticleIndex", label = "Current Particle Index", format = "number" },
			{ key = "declinationAngle", label = "Declination Angle", format = "number" },
			{ key = "declinationAngleVariation", label = "Declination Angle Variation", format = "number" },
			{ key = "emitStartTime", label = "Emit Start Time", format = "number" },
			{ key = "emitStopTime", label = "Emit Stop Time", format = "number" },
			{ key = "emitter", label = "Emitter", format = "object" },
			{ key = "emitterDepth", label = "Emitter Depth", format = "number" },
			{ key = "emitterHeight", label = "Emitter Height", format = "number" },
			{ key = "emitterModifiers", label = "Emitter Modifiers", render = "objectLinks" },
			{ key = "emitterWidth", label = "Emitter Width", format = "number" },
			{ key = "firstTime", label = "First Time", format = "number" },
			{ key = "initialColor", label = "Initial Color", format = "color" },
			{ key = "initialNormal", label = "Initial Normal", format = "vector3" },
			{ key = "initialSize", label = "Initial Size", format = "number" },
			{ key = "lastEmit", label = "Last Emit", format = "number" },
			{ key = "lifespan", label = "Lifespan", format = "number" },
			{ key = "lifespanVariance", label = "Lifespan Variance", format = "number" },
			{ key = "particleColliders", label = "Particle Colliders", render = "objectLinks" },
			{ key = "particleData", label = "Particle Data", format = "list" },
			{ key = "particleDataCount", label = "Particle Data Count", format = "number" },
			{ key = "particleModifiers", label = "Particle Modifiers", render = "objectLinks" },
			{ key = "planarAngle", label = "Planar Angle", format = "number" },
			{ key = "planarAngleVariation", label = "Planar Angle Variation", format = "number" },
			{ key = "resetParticleSystem", label = "Reset Particle System", format = "boolean" },
			{ key = "scaledLastTime", label = "Scaled Last Time", format = "number" },
			{ key = "spawnDirectionChaos", label = "Spawn Direction Chaos", format = "number" },
			{ key = "spawnGenerationsCount", label = "Spawn Generations Count", format = "number" },
			{ key = "spawnMultiplier", label = "Spawn Multiplier", format = "number" },
			{ key = "spawnOnDeath", label = "Spawn On Death", format = "boolean" },
			{ key = "spawnPercentage", label = "Spawn Percentage", format = "number" },
			{ key = "spawnSpeedChaos", label = "Spawn Speed Chaos", format = "number" },
			{ key = "speed", label = "Speed", format = "number" },
			{ key = "speedVariation", label = "Speed Variation", format = "number" },
			{ key = "staticBounds", label = "Static Bounds", format = "boolean" },
			{ key = "useBirthRate", label = "Use Birth Rate", format = "boolean" },
		},
	},
	niColorData = {
		label = "NiColorData",
		fields = {
			{ key = "keyCount", label = "Key Count", format = "number" },
			{ key = "keys", label = "Keys", format = "list" },
			{ key = "keyType", label = "Key Type", format = "value" },
		},
	},
	niKeyframeData = {
		label = "NiKeyframeData",
		fields = {
			{ key = "positionKeyCount", label = "Position Key Count", format = "number" },
			{ key = "positionKeys", label = "Position Keys", format = "list" },
			{ key = "positionType", label = "Position Type", format = "value" },
			{ key = "rotationKeyCount", label = "Rotation Key Count", format = "number" },
			{ key = "rotationKeys", label = "Rotation Keys", format = "list" },
			{ key = "rotationType", label = "Rotation Type", format = "value" },
			{ key = "scaleKeyCount", label = "Scale Key Count", format = "number" },
			{ key = "scaleKeys", label = "Scale Keys", format = "list" },
			{ key = "scaleType", label = "Scale Type", format = "value" },
		},
	},
	niPixelData = {
		label = "NiPixelData",
		fields = {
			{ key = "bytesPerPixel", label = "Bytes Per Pixel", format = "number" },
			{ key = "mipMapLevels", label = "Mip Map Levels", format = "number" },
		},
	},
	niSourceTexture = {
		label = "NiSourceTexture",
		fields = {
			{ key = "fileName", label = "File Name", format = "text" },
			{ key = "isStatic", label = "Is Static", format = "boolean" },
			{ key = "pixelData", label = "Pixel Data", format = "object" },
			{ key = "platformFilename", label = "Platform Filename", format = "text" },
		},
	},
}

--- @param object niObject
--- @return string[]
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

--- @param field { format?: string|fun(value:any, field:table):any }
--- @param value nil|boolean|number|string|table|userdata
--- @return nil|boolean|number|string
local function formatFieldValue(field, value)
	local formatter = field.format
	if type(formatter) == "function" then
		return formatter(value, field)
	end

	local handler = formatters[formatter or "value"] or formatters.value
	return handler(value)
end

--- @param object niObject
--- @return string[]
function types.getLineage(object)
	return buildLineage(object)
end

--- @param object niObject
--- @return table[]
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
				elseif field.render == "effectLinks" then
					value = collectEffectList(value)
				elseif field.render == "objectLinks" then
					value = collectObjectList(value)
				elseif field.render == "mapLinks" then
					value = collectMapList(value)
				end

				local displayValue = formatFieldValue(field, value)
				if field.render == "propertyLinks" or field.render == "effectLinks" or field.render == "objectLinks" or field.render == "mapLinks" then
					displayValue = formatListSummary(value)
				elseif field.render == "mapLink" then
					displayValue = formatTexturingPropertyMapSummary(value)
				end

				table.insert(rows, {
					label = field.label or field.key,
					value = displayValue,
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

--- @param object niObject
--- @return number[]|nil
function types.getColor(object)
	for _, typeName in ipairs(buildLineage(object)) do
		local definition = types.definitions[normalizeTypeName(typeName)]
		if definition and definition.color then
			return definition.color
		end
	end

	return nil
end

--- @param pane tes3uiElement
--- @param object niObject
--- @param helpers SceneInspectorDetailHelpers|nil
function types.renderDetailPane(pane, object, helpers)
	helpers = helpers or {}
	local addSectionHeader = helpers.addSectionHeader
	local addValueRow = helpers.addValueRow
	local addLinkRow = helpers.addLinkRow
	local addLinkListRow = helpers.addLinkListRow
	local showMapPopup = helpers.showMapPopup
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

	for _, section in ipairs(sections) do
		addSectionHeader(pane, section.label)
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

					addLinkRow(pane, row.label, string.format("%s (%s)", controllerName, getRTTIName(controller)), function()
						focusObject(controller)
					end)
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
			elseif field.render == "effectLinks" then
				if type(addLinkListRow) ~= "function" or type(focusObject) ~= "function" then
					error("Scene Inspector types.lua requires addLinkListRow and focusObject helpers for effect links.")
				end

				local items = {}
				for _, effect in ipairs(row.rawValue or {}) do
					table.insert(items, {
						text = getRTTIName(effect),
						value = effect,
					})
				end

				addLinkListRow(pane, row.label, items, function(effect)
					focusObject(effect)
				end)
			elseif field.render == "objectLinks" then
				if type(addLinkListRow) ~= "function" or type(focusObject) ~= "function" then
					error("Scene Inspector types.lua requires addLinkListRow and focusObject helpers for object links.")
				end

				local items = {}
				for _, objectValue in ipairs(row.rawValue or {}) do
					table.insert(items, {
						text = formatObjectSummary(objectValue),
						value = objectValue,
					})
				end

				addLinkListRow(pane, row.label, items, function(objectValue)
					focusObject(objectValue)
				end)
			elseif field.render == "mapLink" then
				if type(addLinkRow) ~= "function" or type(showMapPopup) ~= "function" then
					error("Scene Inspector types.lua requires addLinkRow and showMapPopup helpers for map links.")
				end

				local map = row.rawValue
				if map then
					addLinkRow(pane, row.label, formatTexturingPropertyMapSummary(map), function()
						showMapPopup(map, row.label)
					end)
				else
					addValueRow(pane, row.label, "None")
				end
			elseif field.render == "mapLinks" then
				if type(addLinkListRow) ~= "function" or type(showMapPopup) ~= "function" then
					error("Scene Inspector types.lua requires addLinkListRow and showMapPopup helpers for map links.")
				end

				local items = {}
				for _, map in ipairs(row.rawValue or {}) do
					table.insert(items, {
						text = formatTexturingPropertyMapSummary(map),
						value = map,
					})
				end

				addLinkListRow(pane, row.label, items, function(map)
					showMapPopup(map, row.label)
				end)
			elseif field.format == "object" then
				if type(addLinkRow) ~= "function" or type(focusObject) ~= "function" then
					error("Scene Inspector types.lua requires addLinkRow and focusObject helpers for object links.")
				end

				local objectValue = row.rawValue
				if objectValue then
					addLinkRow(pane, row.label, formatObjectSummary(objectValue), function()
						focusObject(objectValue)
					end)
				else
					addValueRow(pane, row.label, "None")
				end
			else
				addValueRow(pane, row.label, row.value)
			end
		end
	end
end

--- @param pane tes3uiElement
--- @param map SceneInspectorTexturingPropertyMap
--- @param helpers SceneInspectorDetailHelpers|nil
--- @return nil
function types.renderTexturingPropertyMapPane(pane, map, helpers)
	helpers = helpers or {}
	local addValueRow = helpers.addValueRow
	local addLinkRow = helpers.addLinkRow
	local focusObject = helpers.focusObject

	if type(addValueRow) ~= "function" then
		error("Scene Inspector types.lua requires addValueRow helper for texturing property maps.")
	end

	local texture = safeIndex(map, "texture")
	if texture and type(addLinkRow) == "function" and type(focusObject) == "function" then
		addLinkRow(pane, "Texture", formatObjectSummary(texture), function()
			focusObject(texture)
		end)
	else
		addValueRow(pane, "Texture", texture and formatObjectSummary(texture) or "None")
	end

	addValueRow(pane, "Clamp Mode", formatValue(safeIndex(map, "clampMode")) or "nil")
	addValueRow(pane, "Filter Mode", formatValue(safeIndex(map, "filterMode")) or "nil")
	addValueRow(pane, "Tex Coord Set", formatValue(safeIndex(map, "texCoordSet")) or "nil")
end

return types
