
local config = mwse.loadConfig("ImprovedORI", {
	logToFile = true,
	replace = true,
})

local variableTypeToFullName = {
	f = "float",
	l = "long",
	s = "short",
}

local function logToConsoleAndFile(fmt, ...)
	local str = fmt:format(...)
	tes3ui.log(str)
	mwse.log(str)
end

local function ori()
	local reference = tes3ui.findMenu("MenuConsole"):getPropertyObject("MenuConsole_current_ref")
	if (not reference) then
		tes3ui.log("ERROR: No reference selected.")
		return
	end

	local log = tes3ui.log
	if (config.logToFile) then
		log = logToConsoleAndFile
		mwse.log("--------------------")
	end

	-- Basic data we care about.
	local baseObject = reference.baseObject
	local cell = reference.cell

	-- Show basic information
	log("Reference: %s (%s)", reference, reference.sourceMod or "N/A")
	log("Base Object: %s (%s)", baseObject, baseObject.sourceMod or "N/A")
	if (reference.sourceFormId + reference.sourceModId + reference.targetFormId + reference.targetModId > 0) then
		log("Source/Target IDs: %d (%d) -> %d (%d)", reference.sourceFormId, reference.sourceModId, reference.targetFormId, reference.targetModId)
	end
	log("Cell: %s", cell.editorName)

	-- Show ownership information
	local owner, ownerReq = tes3.getOwner({ reference = reference })
	if (owner) then
		log("Owner: %s", owner)
		if (ownerReq) then
			if (owner.objectType == tes3.objectType.faction) then
				log("  Requirement: Rank %d (%s)", ownerReq, owner:getRankName(ownerReq))
			else
				log("  Requirement: Global '%s' > 0", ownerReq)
			end
		end
	end

	-- Is this a leveled spawn?
	local leveledBaseReference = reference.leveledBaseReference
	if (leveledBaseReference) then
		log("Leveled Reference: %s (%s)", leveledBaseReference, leveledBaseReference.sourceMod or "N/A")

		local leveledBaseObject = leveledBaseReference.baseObject
		log("  Leveled List: %s (%s)", leveledBaseObject, leveledBaseObject.sourceMod or "N/A")
	end

	-- Display mesh and head/hair data
	local meshSource, meshPath = tes3.getFileSource(string.format("meshes\\%s", baseObject.mesh))
	if (meshSource ~= 0) then
		log("Mesh: Data Files\\%s (%s)", meshPath, meshSource)

		-- Show head/hair for NPCs.
		if (baseObject.objectType == tes3.objectType.npc) then
			local headSource, headPath = tes3.getFileSource(string.format("meshes\\%s", baseObject.head.mesh))
			log("  Head: %s", baseObject.head.id)
			log("    Path: Data Files\\%s (%s)", headPath, headSource)

			local hairSource, hairPath = tes3.getFileSource(string.format("meshes\\%s", baseObject.hair.mesh))
			log("  Hair: %s", baseObject.hair.id)
			log("    Path: Data Files\\%s (%s)", hairPath, hairSource)
		end

		-- Go through and show any associated textures, using :lower() to ensure no weird duplicates
		local usedTextures = {}
		for node in table.traverse({ reference.sceneNode }, "children") do
			local texturingProperty = node:getProperty(0x4)
			if (texturingProperty and texturingProperty.maps[1]) then
				for _, map in ipairs(texturingProperty.maps) do
					if (map and map.texture) then
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

		-- Show them to the user
		for _, v in ipairs(texturesSorted) do
			local textureSource, texturePath = tes3.getFileSource(string.format("textures\\%s", v))
			log("  Texture: %s (%s)", texturePath, textureSource)
		end
	end

	-- Display script and script variables
	if (baseObject.script) then
		log("Script: %s (%s)", baseObject.script, baseObject.script.sourceMod or "N/A")

		-- Get sorted list of variables
		local variables = reference.context:getVariableData()
		local variablesSorted = {}
		for k, v in pairs(variables) do
			v.name = k
			table.insert(variablesSorted, v)
		end
		table.sort(variablesSorted, function(a, b) return a.name:lower() < b.name:lower() end)

		for _, v in ipairs(variablesSorted) do
			log("  %s = %s (%s)", v.name, v.value, variableTypeToFullName[v.type])
		end
	end

	if (config.logToFile) then
		mwse.log("--------------------")
	end
end

-- Allow ori() to be called from the lua console.
local function addBetterORI(e)
	e.sandbox.ori = ori
end
event.register("UIEXP:sandboxConsole", addBetterORI)

-- Allow the original ori command to be replaced with the custom one.
local function onConsoleCommand(e)
	if (config.replace and e.command:lower() == "ori") then
		tes3ui.logToConsole(e.command, true)
		ori()
		return false
	end
end
event.register("UIEXP:consoleCommand", onConsoleCommand, { filter = "mwscript" })
