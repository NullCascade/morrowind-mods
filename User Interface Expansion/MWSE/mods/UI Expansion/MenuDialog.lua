
local common = require("UI Expansion.common")

local GUI_ID_MenuDialog = tes3ui.registerID("MenuDialog")
local GUI_ID_MenuDialog_a_topic = tes3ui.registerID("MenuDialog_a_topic")
local GUI_ID_MenuDialog_answer_block = tes3ui.registerID("MenuDialog_answer_block")
local GUI_ID_MenuDialog_hyper = tes3ui.registerID("MenuDialog_hyper")
local GUI_ID_MenuDialog_scroll_pane = tes3ui.registerID("MenuDialog_scroll_pane")
local GUI_ID_MenuDialog_topics_pane = tes3ui.registerID("MenuDialog_topics_pane")

local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local GUI_Palette_TopicSeen = common.getColor(common.config.dialogueTopicSeenColor)
local GUI_Palette_TopicUnique = common.getColor(common.config.dialogueTopicUniqueColor)

----------------------------------------------------------------------------------------------------
-- Dialogue: Adds colorization to show what topics provide new and unique responses.
----------------------------------------------------------------------------------------------------

local function updateTopicsList(e)
	-- If the function lacks context to the dialogue menu, look it up.
	local menuDialogue = tes3ui.findMenu(GUI_ID_MenuDialog)
	local textPane = menuDialogue:findChild(GUI_ID_MenuDialog_scroll_pane):findChild(GUI_ID_PartScrollPane_pane)
	local topicsPane = menuDialogue:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)

	-- Forward along click events to trigger dialogue as usual.
	if (e.source) then
		e.source:forwardEvent(e)

		-- Were we forced out of dialogue?
		if (tes3ui.findMenu(GUI_ID_MenuDialog) == nil) then
			return
		end

		-- Make sure that the first heard from field is always used.
		if (e.info and e.actor and e.info.firstHeardFrom == nil and textPane:findChild(GUI_ID_MenuDialog_answer_block) == nil) then
			e.info.firstHeardFrom = e.actor
		end
	end

	-- Catch events from hyperlinks.
	for _, element in pairs(textPane.children) do
		if (element.id == GUI_ID_MenuDialog_hyper or element.id == GUI_ID_MenuDialog_answer_block) then
			element:register("mouseClick", updateTopicsList)
		end
	end

	-- Get the actor that we're talking with.
	local mobileActor = menuDialogue:getPropertyObject("PartHyperText_actor")
	local actor = mobileActor.reference.object.baseObject

	-- Go through and update all the topics.
	for _, element in pairs(topicsPane.children) do
		-- We only care about topics in this list.
		if (element.id == GUI_ID_MenuDialog_a_topic) then
			element.widget.idleDisabled = GUI_Palette_TopicSeen

			-- Get the info associated with this topic.
			local dialogue = element:getPropertyObject("PartHyperText_dialog")
			local info = dialogue:getInfo({ actor = mobileActor })

			-- Update color scheme on the topic.
			if (info == nil or info.firstHeardFrom) then
				element.widget.state = 2
			elseif (info.actor == actor) then
				-- Topic has actor-unique dialogue, set new state.
				element.widget.state = 4
				element.widget.idleActive = GUI_Palette_TopicUnique
			else
				element.widget.state = 1
			end
			element:triggerEvent("mouseLeave")

			-- Register an event so that we update when any topic is clicked.
			element:register("mouseClick", function(mouseClickEventData)
				mouseClickEventData.info = info
				mouseClickEventData.actor = actor

				updateTopicsList(mouseClickEventData)
			end)
		end
	end
end

local function onDialogueMenuActivated(e)
	-- We only care if this is the first time it was activated.
	if (not e.newlyCreated) then
		return
	end

	-- Set the pre-update event to update the topic list.
	e.element:register("preUpdate", function(preUpdateEventData)
		-- We only want this event to fire once. We'll manually track changes above to be more efficient.
		e.element:unregister("preUpdate")

		updateTopicsList(preUpdateEventData)
	end)
end
event.register("uiActivated", onDialogueMenuActivated, { filter = "MenuDialog" })
