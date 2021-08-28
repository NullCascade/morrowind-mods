local common = require("UI Expansion.common")

--- Calculates the hour and the AM/PM state for a given 24-hour number.
--- @param hour number
--- @return number
--- @return string
local function format12HourTime(hour)
	local hour = math.floor(hour)
	while (hour > 24) do
		hour = hour - 24
	end

	local isAM = true
	if (hour >= 12) then
		hour = hour - 12
		isAM = hour == 12
	end

	if (hour == 0) then
		hour = 12
	end

	return hour, tes3.findGMST(isAM and tes3.gmst.sSaveMenuHelp04 or tes3.gmst.sSaveMenuHelp05).value
end

--- Update text showing when we will finish resting/waiting.
local function updateDesiredHourText()
	local menuRestWait = tes3ui.findMenu("MenuRestWait")
	if (not menuRestWait) then
		return
	end

	local hoursToPass = menuRestWait:findChild("MenuRestWait_scrollbar").widget.current + 1
	local hour, suffix = format12HourTime(tes3.worldController.hour.value + hoursToPass)
	local hoursElement = menuRestWait:findChild("MenuRestWait_hour_text").parent.children[2]
	hoursElement.text = string.format("%s (%s %s)", tes3.findGMST(tes3.gmst.sRestMenu2).value, hour, suffix)
end

--- Create our changes for MenuRestWait.
--- @param e uiActivatedEventData
local function menuRestWait(e)
	if (not e.newlyCreated) then
		return
	end

	local scroll = e.element:findChild("MenuRestWait_scrollbar")
	scroll.widget.max = common.config.maxWait * 24 - 1
	scroll.widget.jump = 4 -- More useful default value.
	scroll:updateLayout()

	-- Enable keyboard input on the scroll bar.
	local wait = e.element:findChild("MenuRestWait_wait_button")
	local rest = e.element:findChild("MenuRestWait_rest_button")
	common.bindScrollBarToKeyboard({
		element = scroll,
		onUpdate = function()
			e.element:updateLayout()
		end,
		onSubmit = function()
			(rest or wait):triggerEvent("mouseClick")
		end,
	})

	-- Show day of week.
	if (common.config.displayWeekday) then
		-- +3 offset, since the 16th of Last Seed (starting day) should be Thurdas.
		local day = common.i18n(string.format("restWait.weekDay.%d", (tes3.worldController.daysPassed.value + 3) % 7 + 1))
		local userFriendlyTimestampElement = e.element.children[2].children[1]
		userFriendlyTimestampElement.text = day .. ", " .. userFriendlyTimestampElement.text
	end

	-- Show rest target hour.
	if (common.config.displayRestTargetHour) then
		e.element:registerAfter("update", updateDesiredHourText)
		updateDesiredHourText()
	end
end
event.register("uiActivated", menuRestWait, { filter = "MenuRestWait" })
