
-- Make sure we have the latest MWSE version.
if (mwse.buildDate < 20200816) then
	event.register("loaded", function()
		tes3.messageBox("Fallen Ash requires an updated version of MWSE. Run MWSE-Updater.")
	end)
	return
end

--- The number of variant textures the mod supports.
local ASH_VARIANTS = 3

--- The number of ash level the mod supports.
local ASH_LEVELS = 3

--- A dictionary of all loaded ash decals. ashDecals.variant.level returns an NiSourceTexture.
local ashDecals = {}

local debugTexture = nil

--- A map with all valid texture paths as keys for quick checking.
local ashDecalPathsToData = {}
local function isAshDecalTexture(path)
    return ashDecalPathsToData[path] ~= nil
end

local function onInitialized()
    -- Load all necessary textures.
    local pathRoot = "textures\\g7\\ash\\%d-%d.dds"
    for v = 1, ASH_VARIANTS do
        ashDecals[v] = {}
        for l = 1, ASH_LEVELS do
            local path = string.format(pathRoot, v, l)
            local texture = niSourceTexture.createFromPath(path)
            -- mwse.log("[Fallen Ash] Loaded texture: %s", texture.fileName)
            ashDecals[v][l] = texture
            ashDecalPathsToData[path] = { variant = v, level = l, texture = texture }
        end
    end

    debugTexture = niSourceTexture.createFromPath("textures\\tx_blood.dds")
end
event.register("initialized", onInitialized)


--------------------------------------------
-- MOD CONFIG MENU                        --
--------------------------------------------

-- Register the mod configuration menu.
local config = require("Fallen Ash.config")

local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\Fallen Ash\\mcm.lua")
end
event.register("modConfigReady", onModConfigReady)


--------------------------------------------
-- UTILITY FUNCTIONS                      --
--------------------------------------------

--- Dictionary of references we've ashified. Key is the reference, value is the ash level.
local managedReferences = {}
local affectedNIFObjects = {}

--- Gets the current ash level for a reference.
--- Currently all textures on a reference have the same level of ashiness.
local function getAshLevelForReference(ref)
    return managedReferences[ref] or 0
end

--- Clean up invalidated references.
local function onObjectInvalidated(e)
    managedReferences[e.object] = nil
end
event.register("objectInvalidated", onObjectInvalidated)

local function traverseNIF(roots)
    local function iter(nodes)
        for i, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

local function getRadius(ref)
    local b = ref.object.boundingBox
    if b == nil then return 0 end
    local c = (b.min + b.max) * 0.5
    local r = math.max(c:distance(b.min), c:distance(b.max))
    return r * ref.scale
end

local function setAshLevelForProperty(object, prop, level)
    -- Scan existing maps to see if there's one we need to update.
    for index, map in ipairs(prop.maps) do
        local texture = map and map.texture
        local fileName = texture and texture.fileName
        if (fileName) then
            local data = ashDecalPathsToData[fileName]
            if (data) then
                if (level == 0) then
                    prop:removeDecalMap(index)
                    -- map.texture = debugTexture
                    -- mwse.log("[Fallen Ash] Removed decal from '%s' (%s)", object.name, object.RTTI.name)
                else
                    map.texture = ashDecals[data.variant][level]
                    table.insert(affectedNIFObjects, object)
                    -- mwse.log("[Fallen Ash] Updated decal for '%s' (%s): %d-%d", object.name, object.RTTI.name, data.variant, level)
                end
                return
            end
        end
    end

    -- No existing map, add one.
    if (level > 0) then
        if (prop.canAddDecal) then
            -- prop = object:detachProperty(0x4):clone()
            -- object:attachProperty(prop)

            local variant = math.random(1, ASH_VARIANTS)
            local map, index = prop:addDecalMap(ashDecals[variant][level])
            if (map) then
                -- mwse.log("[Fallen Ash] Added decal %d-%d to '%s' (%s) at index %d", variant, level, object.name, object.RTTI.name, index)
            end
        end
    end
end

local function setAshLevelForReference(ref, level)
    -- mwse.log("[Fallen Ash] Setting '%s' to level %d.", ref, level)

    if config.ignoreActors and ref.object.fatigue then
        -- mwse.log("[Fallen Ash] ignore actor (%s)", ref)
        return
    elseif config.ignoreItems and ref.object.weight then
        -- mwse.log("[Fallen Ash] ignore item (%s)", ref)
        return
    elseif config.blacklist[ref.object.id:lower()] then
        -- mwse.log("[Fallen Ash] ignore blacklisted (%s)", ref)
        return
    elseif tonumber(config.minimumSize) > getRadius(ref) then
        -- mwse.log("[Fallen Ash] ignore small size (%s)", ref)
        return
    end

    if (getAshLevelForReference(ref) == level) then
        return
    end

    for node in traverseNIF({ ref.sceneNode }) do
        local success, texturingProperty, alphaProperty = pcall(function() return node:getProperty(0x4), node:getProperty(0x0) end)
        if (success and texturingProperty and not alphaProperty) then
            setAshLevelForProperty(node, texturingProperty, level)
        end
    end

    managedReferences[ref] = level
end

local function clearAllAshDecals()
    for _, object in ipairs(affectedNIFObjects) do
        local success, texturingProperty = pcall(function() return object:getProperty(0x4) end)
        if (success and texturingProperty) then
            setAshLevelForProperty(object, texturingProperty, 0)
        end
    end
    managedReferences = {}
    affectedNIFObjects = {}
    -- mwse.log("[Fallen Ash] Cleared all decals.")
end

--- Determine localized ash level based on current weather.
local function determineLocalAshLevel()
    local weatherController = tes3.worldController.weatherController
    local currentWeather = weatherController.currentWeather
    local nextWeather = weatherController.nextWeather

    if (tes3.getPlayerCell().region == nil) then
        return 0, true
    end

    -- Determine our weather state.
    if (currentWeather and currentWeather.index == tes3.weather.ash) then
        if (nextWeather) then
            -- We're transitioning out of an ash storm.
            return math.floor(ASH_LEVELS * (1-weatherController.transitionScalar)), true
        else
            -- We're in a stable ash storm.
            return ASH_LEVELS, false
        end
    elseif (nextWeather and nextWeather.index == tes3.weather.ash) then
        -- We are in the process of ashing.
        return math.floor(ASH_LEVELS * weatherController.transitionScalar), false
    end

    return 0, true
end


--------------------------------------------
-- CELL TRANSITION HANDLING               --
--------------------------------------------

local countDownToUpdate = 10

local function setAshLevelForActiveCells(level)
    -- mwse.log("[Fallen Ash] Setting active cell ash level to %d.", level)
    local playerPos = tes3.player.position
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            if (ref.sceneNode ~= nil and ref.disabled == false and getAshLevelForReference(ref) ~= level and playerPos:distance(ref.position) < 2048) then
                setAshLevelForReference(ref, level)
            end
        end
    end

    -- Player needs to be updated manually.
    setAshLevelForReference(tes3.player, level)
    setAshLevelForReference(tes3.mobilePlayer.firstPersonReference, level)

    -- mwse.log("[Fallen Ash] Finished setting active cell ash level to %d.", level)
end

local function onCellChanged(e)
    local old = e.previousCell
    local new = e.cell

    -- We don't update anything unless we've changed regions.
    if (old and old.region == new.region) then
        return
    end

    -- Start fresh.
    clearAllAshDecals()

    -- Bail if the new cell has no region or it isn't ashy.
    if (new.region == nil or new.region.weather.index ~= tes3.weather.ash) then
        return
    end

    -- Find nearby references to the player, and decal them up.
    setAshLevelForActiveCells(determineLocalAshLevel())
    countDownToUpdate = 10
end
event.register("cellChanged", onCellChanged)

--------------------------------------------
-- WEATHER TRANSITION HANDLING            --
--------------------------------------------

local function onWeatherTransitionStarted(e)
    -- mwse.log("[Fallen Ash] Starting transitioning weather from %s to %s.", table.find(tes3.weather, e.from.index), table.find(tes3.weather, e.to.index))
end
-- event.register("weatherTransitionStarted", onWeatherTransitionStarted)

local function onWeatherTransitionFinished(e)
    -- mwse.log("[Fallen Ash] Finished transitioning weather to %s.", table.find(tes3.weather, e.to.index))
end
-- event.register("weatherTransitionFinished", onWeatherTransitionFinished)

local function onWeatherChangedImmediate(e)
    -- mwse.log("[Fallen Ash] Weather changed immediately to %s.", table.find(tes3.weather, e.to.index))
    setAshLevelForActiveCells(determineLocalAshLevel())
    countDownToUpdate = 10
end
event.register("weatherChangedImmediate", onWeatherChangedImmediate)

local function onWeatherCycled(e)
    -- mwse.log("[Fallen Ash] Weather cycled.")
end
-- event.register("weatherCycled", onWeatherCycled)

--------------------------------------------
-- OTHER MISC. HANDLING                   --
--------------------------------------------

--- Persistent timers: Coming soon...
local function onSimulate(e)
    countDownToUpdate = countDownToUpdate - e.delta
    if (countDownToUpdate <= 0) then
        -- local weatherController = tes3.worldController.weatherController
        -- local currentWeather = weatherController.currentWeather
        -- local nextWeather = weatherController.nextWeather

        local ashLevel, skipUpdate = determineLocalAshLevel()

        -- mwse.log("[Fallen Ash] Forcing update due to time passed. Level: %d; Skip: %s; Weather: %s -> %s @ %.2f.", ashLevel, skipUpdate, currentWeather and table.find(tes3.weather, currentWeather.index), nextWeather and table.find(tes3.weather, nextWeather.index), weatherController.transitionScalar)

        if (not skipUpdate) then
            setAshLevelForActiveCells(ashLevel)
        end

        countDownToUpdate = 10
    end
end
event.register("simulate", onSimulate)

local function onLoad(e)
    clearAllAshDecals()
end
event.register("load", onLoad)

--- Fixup body parts that are assigned after a level has already been set.
local function onBodyPartsUpdated(e)
    local level = getAshLevelForReference(e.reference)
    if (e.reference and level ~= 0) then
        for node in traverseNIF({ e.reference.sceneNode }) do
            local success, texturingProperty, alphaProperty = pcall(function() return node:getProperty(0x4), node:getProperty(0x0) end)
            if (success and texturingProperty and not alphaProperty) then
                setAshLevelForProperty(node, texturingProperty, level)
            end
        end
    end
end
event.register("bodyPartsUpdated", onBodyPartsUpdated)


--------------------------------------------
-- DEBUG CODE                             --
--------------------------------------------

local function debugToggleAshWeather(e)
    if (not e.isAltDown) then
        -- mwse.log("[Fallen Ash] Press alt dumbass.")
        return
    end

    local region = tes3.getRegion()
    if (region == nil) then
        -- mwse.log("[Fallen Ash] Could not determine region.")
        return
    end

    local currentWeather = region.weather
    if (currentWeather == nil) then
        -- mwse.log("[Fallen Ash] Current weather not defined.")
        return
    end

    if (currentWeather.index == tes3.weather.ash) then
        -- mwse.log("[Fallen Ash] Setting clear weather.")
        region:changeWeather(tes3.weather.clear)
    else
        -- mwse.log("[Fallen Ash] Setting ash weather.")
        region:changeWeather(tes3.weather.ash)
    end
end
-- event.register("keyDown", debugToggleAshWeather, { filter = tes3.scanCode.z })

local function debugAdjustAshLevel(e)
    local hit = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector() })
    local ref = hit and hit.reference
    if (ref == nil) then
        -- mwse.log("[Fallen Ash] No reference found.")
        return
    end

    local currentLevel = getAshLevelForReference(ref)
    local newLevel = currentLevel
    if (e.isAltDown) then
        newLevel = math.max(currentLevel - 1, 0)
    else
        newLevel = math.min(currentLevel + 1, ASH_LEVELS)
    end
    -- mwse.log("[Fallen Ash] Setting ash level for '%s' from %d to %d.", ref, currentLevel, newLevel)
    setAshLevelForReference(ref, newLevel)
end
-- event.register("keyDown", debugAdjustAshLevel, { filter = tes3.scanCode.x })

local function debugRefocusAshLevel(e)
    if (e.isAltDown) then
        clearAllAshDecals()
        -- mwse.log("[Fallen Ash] Force cleared all decals.")
    else
        setAshLevelForActiveCells(determineLocalAshLevel())
        -- mwse.log("[Fallen Ash] Force updated all decals.")
    end
    countDownToUpdate = 10
end
-- event.register("keyDown", debugRefocusAshLevel, { filter = tes3.scanCode.c })
