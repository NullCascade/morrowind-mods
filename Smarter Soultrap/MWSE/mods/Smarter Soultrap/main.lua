--[[
	Intelligent Soultrap
	
	Inspired by GIST - Genuinely Intelligent Soul Trap by opusGlass: https://www.nexusmods.com/skyrimspecialedition/mods/15755
]]

-- Grab our submodules.
local config = require("Smarter Soultrap.config")
local interop = require("Smarter Soultrap.interop")

-- Setup MCM.
local function registerModConfig()
	mwse.mcm.registerMCM(require("Smarter Soultrap.mcm"))
end
event.register("modConfigReady", registerModConfig)

-- Temporary upvalue variables.
local availableSoulGemStacks
local soulCapacity

-- Cache for soulgem objects.
local soulGemDataMap = {}
local function onInitialized()
	for item in tes3.iterateObjects(tes3.objectType.miscItem) do
		local soulGemData = item.soulGemData
		if (soulGemData) then
			soulGemDataMap[item] = soulGemData
		end
	end
end
event.register("initialized", onInitialized, { priority = -1 })

local function checkLevelRequirement(caster, key)
	-- Make sure the feature is enabled.
	if (not config[key]) then
		return false
	end

	-- Does it have a level requirement?
	if (config.leveling) then
		local playerSkill = caster:getSkillValue(tes3.skill[config.levelingSkill])
		if (playerSkill < config.levelRequirements[key]) then
			return false
		end
	end

	return true

end

local function getSoulgemCapacity(object)
	return soulGemDataMap[object].value * tes3.findGMST(tes3.gmst.fSoulGemMult)
end

--- @param caster tes3mobileActor
--- @param target tes3creature
--- @param targetMobile tes3mobileActor
local function addSoul(caster, target, targetMobile)
	-- A displaced soul, if applicable.
	local canDisplace = checkLevelRequirement(caster, "displacement")
	local displaced = nil

	-- Find the best soulgem to fill.
	local targetSoulValue = target.soul
	local bestStack, bestItemData
	for _, stack in ipairs(availableSoulGemStacks) do
		-- We need to reimplement the filterSoulGemTarget event.
		local filterSoulGemTarget = event.trigger("filterSoulGemTarget", { soulGem = stack.object, actor = target, mobile = targetMobile, reference = targetMobile and targetMobile.reference })
		if (not filterSoulGemTarget.filter) then
			-- Does the soul fit in this gem?
			if (targetSoulValue <= soulCapacity[stack.object]) then
				local emptyCount = stack.count - (stack.variables and #stack.variables or 0)
				if (emptyCount > 0) then
					bestStack = stack
					bestItemData = nil
				else
					for _, itemData in ipairs(stack.variables) do
						if (bestItemData) then
							if (itemData.soul.soul < bestItemData.soul.soul) then
								bestStack = stack
								bestItemData = itemData
							end
						else
							if (itemData.soul.soul < targetSoulValue) then
								bestStack = stack
								bestItemData = itemData
							end
						end
					end
				end
			end
		end

	end

	-- Did we find a valid thing to fill?
	local success = false
	if (bestStack) then
		-- Are we replacing something?
		if (bestItemData) then
			displaced = bestItemData.soul
			bestItemData.soul = target
			success = true
		else
			-- We have to make a new itemdata.
			local itemData = tes3.addItemData({ to = caster, item = bestStack.object })
			if (itemData) then
				itemData.charge = 0 -- Hacky workaround...
				itemData.soul = target
				success = true
			end
		end
	end

	-- What message are we showing?
	if (displaced and config.showDisplacementMessage) then
	end

	-- Do we have a displaced soul we can relocate?
	if (displaced) then
		local message = nil
		if (config.showDisplacementMessage) then
			message = string.format("%s was displaced from %s", displaced.name, bestStack.object.name)
		end

		-- Check for relocation.
		if (checkLevelRequirement(caster, "relocation")) then
			local replaced, replacedTo = addSoul(caster, displaced)
			if (replaced) then
				message = string.format("%s was relocated from %s to %s", displaced.name, bestStack.object.name, replacedTo.name)
			end
		end

		if (message) then
			tes3.messageBox(message)
		end
	end

	return success, bestStack and bestStack.object
end

--- Called via our patch to fill a soul gem.
--- @param caster tes3mobileActor
--- @param target tes3mobileActor
local function doSoulTrapFill(caster, target)
	-- Run through our caster's inventory and collect available soulgem stacks.
	availableSoulGemStacks = {}
	for _, stack in pairs(caster.reference.object.inventory) do
		if (soulGemDataMap[stack.object]) then
			table.insert(availableSoulGemStacks, stack)
		end
	end

	-- No soul gems? Bail.
	if (#availableSoulGemStacks == 0) then
		return false
	end

	-- Cache soulgem capacity. We want to keep this fresh in case someone changes the GMST.
	soulCapacity = {}
	local fSoulGemMult = tes3.findGMST(tes3.gmst.fSoulGemMult).value
	for _, stack in ipairs(availableSoulGemStacks) do
		soulCapacity[stack.object] = soulGemDataMap[stack.object].value * fSoulGemMult
	end

	-- We want to sort our results so smallest soulgems are latest.
	table.sort(availableSoulGemStacks, function(a, b) return soulCapacity[a.object] > soulCapacity[b.object] end)

	-- We have all of the data we need... now do some work.
	if (not addSoul(caster, target.reference.object, target)) then
		return false
	end

	-- Displace a message showing successful trap.
	if (config.showSoultrapMessage) then
		tes3.messageBox(tes3.findGMST(tes3.gmst.sSoultrapSuccess).value)
	end

	return true
end

-- Expose some of our common functions into the interop module.
interop.addSoul = addSoul
interop.checkLevelRequirement = checkLevelRequirement

-- Create our custom patch to hijack soulgem filling. We could use events for this, but...
--[[
	Before:
		004633C3 014                 push    ebp             ; target
		004633C4 018                 call    MobileActor::getReferenceObject
		004633C4
		004633C9 018                 mov     ecx, eax
		004633CB 018                 add     ecx, 3Ch        ; caster.object.inventory
		004633CE 018                 call    Inventory::fillSoulGemForActor
	After:
		004633C3 014                 push    ebp             ; target
		004633CE 018                 call    Inventory::fillSoulGemForActor
]]
assert(mwse.memory.writeNoOperation({ address = 0x4633C4, length = 0xA }))
assert(mwse.memory.writeFunctionCall({ address = 0x4633CE, previousCall = 0x49AC30, call = doSoulTrapFill, signature = { this = "tes3mobileObject", arguments = { "tes3mobileObject" }, returns = "bool" } }))
mwse.log("[Smarter Soultrap] Initialized.")
