local this = {}

local shared = require("Controlled Consumption.shared")

-- Name to identify this module.
this.name = "Oblivion Style"
this.consumeVersion = 1.2

-- Callback for when the config is created.
function this.onConfigCreate(container)
	-- Required for text to initially wrap.
	container:getTopLevelParent():updateLayout()

	-- No real config. Just a description.
	local description = container:createLabel({ text = "This module replicates the alchemy restrictions in Oblivion. The player may have 4 active potions at any one time." })
	description.layoutWidthFraction = 1.0
	description.wrapText = true
end

-- How many timers we can sustain before potion drinking is blocked.
local potionLimit = 4

-- A list of current cooldown timers.
local cooldownTimers = {}

-- When the timer completes, we hide the frame alchemy icon and clear our list.
local function onTimerComplete(e)
	-- Remove the timer from our active list.
	table.removevalue(cooldownTimers, e.timer)

	-- If we aren't maxed on potions, hide the block icon.
	if (#cooldownTimers < potionLimit and shared.alchemyFrame) then
		shared.alchemyFrame.visible = false
	end
end

-- Our main logic for seeing if a potion can be consumed or not.
function this.onEquip(e)
	-- Make some basic checks (player equipping, it's a potion, etc).
	if (not shared.basicPotionChecks(e)) then
		return
	end

	-- Do we already have a potion active?
	if (#cooldownTimers >= potionLimit) then
		tes3.messageBox("You may not have more than %d potions active at once.", #cooldownTimers)
		return false
	end

	-- Start our cooldown based on the longest effect duration. Use game time so that resting affects it.
	local duration = shared.getLongestPotionDuration(e.item) * (1/3600) * tes3.getGlobal("timescale")
	table.insert(cooldownTimers, timer.start({ type = timer.game, duration = duration, callback = onTimerComplete }))
	
	-- If we are maxed on potions, show the block icon.
	if (#cooldownTimers >= potionLimit and shared.alchemyFrame) then
		shared.alchemyFrame.visible = true
	end
end

-- Set any remaining time so that it persists through saves.
function this.onSave(e)
	local data = shared.getPersistentData()
	
	-- Get the time left in each timer and store it in an array.
	local timeLeftArray = {}
	for i = 1, #cooldownTimers do
		table.insert(timeLeftArray, cooldownTimers[i].timeLeft)
	end
	data.nc.consume.oblivionTimers = timeLeftArray
end

-- Loaded event. Resume any consumption restrictions.
function this.onLoaded(e)
	local data = shared.getPersistentData()

	-- Ensure our timer list is empty.
	cooldownTimers = {}

	local timers = data.nc.consume.oblivionTimers
	if (timers) then
		-- We drank recently. Start timer with the remaining time left.
		for i = 1, #timers do
			table.insert(cooldownTimers, timer.start({ type = timer.game, duration = timers[i], callback = onTimerComplete }))
		end

		-- Also show the blocked icon.
		if (#timers >= potionLimit and shared.alchemyFrame) then
			shared.alchemyFrame.visible = true
		end
	else
		-- Make sure the icon is hidden if we're loading a save where we didn't just drink a potion.
		if (shared.alchemyFrame) then
			shared.alchemyFrame.visible = false
		end
	end
end

-- Callback for when this module is set as the active one.
function this.onSetActive()
	-- Delete any save data.
	local data = shared.getPersistentData()
	if (data) then
		data.nc.consume.oblivionTimers = nil
	end

	-- Also unset any data in our module.
	cooldownTimers = {}

	-- Setup the events we care about.
	event.register("equip", this.onEquip)
	event.register("save", this.onSave)
	event.register("loaded", this.onLoaded)
end

-- Callback for when this module is turned off.
function this.onSetInactive()
	-- Delete any save data.
	local data = shared.getPersistentData()
	if (data) then
		data.nc.consume.oblivionTimers = nil
	end

	-- Also unset any data in our module.
	cooldownTimers = {}
	
	-- Remove the events we cared about.
	event.unregister("equip", this.onEquip)
	event.unregister("save", this.onSave)
	event.unregister("loaded", this.onLoaded)
end

return this