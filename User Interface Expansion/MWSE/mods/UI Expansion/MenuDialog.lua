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

--- Check to see if the player has used a number key to select a response.
--- @param e keyDownEventData
local function checkForAnswerHotkey(e)
	-- Make sure we're in the dialogue menu.
	local topMenu = tes3.getTopMenu()
	if not topMenu then
		return
	end
	if not (topMenu.id == GUI_ID_MenuDialog) then
		return
	end

	-- Make sure we're not doing text input.
	if (common.isTextInputActive()) then
		return
	end

	local key = tes3.scanCodeToNumber[e.keyCode]
	if not key then
		return
	end

	-- Do we have any answers?
	local firstAnswer = topMenu:findChild("MenuDialog_answer_block")
	if not firstAnswer then
		return
	end

	-- Get a lsit of answers.
	local answers = {}
	for _, child in ipairs(firstAnswer.parent.children) do
		if (child.id == firstAnswer.id) then
			table.insert(answers, child)
		end
	end

	local answer = answers[key]
	if answer then
		answer:triggerEvent("mouseClick")
	end
end
event.register("keyDown", checkForAnswerHotkey)

--- Updates colors on topic lists, and registers to let us know when they are needed.
--- @param e tes3uiEventData
local function updateTopicsList(e)
	-- If the function lacks context to the dialogue menu, look it up.
	local menuDialogue = tes3ui.findMenu(GUI_ID_MenuDialog)
	local textPane = menuDialogue:findChild(GUI_ID_MenuDialog_scroll_pane):findChild(GUI_ID_PartScrollPane_pane)
	local topicsPane = menuDialogue:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)

	e.info = e.source:getPropertyObject("MenuDialog_UIEXP_info")
	e.actor = e.source:getPropertyObject("MenuDialog_UIEXP_actor")

	-- Forward along click events to trigger dialogue as usual.
	if (e.source) then
		-- Were we forced out of dialogue?
		if (tes3ui.findMenu(GUI_ID_MenuDialog) == nil) then
			return
		end

		-- Make sure that the node heard from field is always used.
		if e.info then
			if e.actor then
				if (e.info.firstHeardFrom == nil) then
					if (textPane:findChild(GUI_ID_MenuDialog_answer_block) == nil) then
						e.info.firstHeardFrom = e.actor
					end
				end
			end
		end
	end

	-- Catch events from hyperlinks.
	for _, element in pairs(textPane.children) do
		if (element.id == GUI_ID_MenuDialog_hyper) then
			element:registerAfter("mouseClick", updateTopicsList)
		end
	end

	-- Get the actor that we're talking with.
	local mobileActor = menuDialogue:getPropertyObject("PartHyperText_actor") --- @type tes3mobileActor
	local actor = mobileActor.reference.object.baseObject --- @type tes3actor

	-- Go through and update all the topics.
	for _, element in pairs(topicsPane.children) do
		-- We only care about topics in this list.
		if (element.id == GUI_ID_MenuDialog_a_topic) then
			element.widget.idleDisabled = GUI_Palette_TopicSeen

			-- Get the info associated with this topic.
			local dialogue = element:getPropertyObject("PartHyperText_dialog") --- @type tes3dialogue
			local info = element:getPropertyObject("") or dialogue:getInfo({ actor = mobileActor })

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

			-- Store objects on the element for quick reference later.
			element:setPropertyObject("MenuDialog_UIEXP_info", info)
			element:setPropertyObject("MenuDialog_UIEXP_actor", actor)

			-- Register an event so that we update when any topic is clicked.
			element:registerAfter("mouseClick", updateTopicsList)
		end
	end
end

--- Updates the dialog menu.
local function update()
	local function traverse(element)
		local path = {}
		local i = 0
		local answerIndex = 0

		local function recursiveTraverse(node)
			if node then
				local children = node.children
				if children then
					if #children > 0 then
						for _, child in pairs(children) do
							recursiveTraverse(child)
						end
					end
				end
				if node.id == GUI_ID_MenuDialog_answer_block then
					local oldText = node.text
					node:registerAfter("mouseClick", updateTopicsList)
					answerIndex = answerIndex + 1
					if not string.match(oldText, "^%d+") then
						node.text = string.format("%d. %s", answerIndex, oldText)
					end
				end
				i = i + 1
				path[i] = node.id .. " " .. node.text
			end
		end

		recursiveTraverse(element)
		return path
	end

	local menuDialog = tes3ui.findMenu(GUI_ID_MenuDialog)
	if menuDialog then
		local scroll_pane = menuDialog:findChild(GUI_ID_MenuDialog_scroll_pane)
		if scroll_pane then
			local pane_pane = scroll_pane:findChild(GUI_ID_PartScrollPane_pane)
			if pane_pane then
				traverse(pane_pane)
			end
		end
	end
end

--- Create our changes for MenuDialog.
--- @param e uiActivatedEventData
local function onDialogueMenuActivated(e)
	-- We only care if this is the node time it was activated.
	if (not e.newlyCreated) then
		return
	end

	-- Set the pre-update event to update the topic list.
	-- We only want this event to fire once. We'll manually track changes above to be more efficient.
	local function firstPreUpdate(preUpdateEventData)
		assert(e.element:unregisterAfter("preUpdate", firstPreUpdate))
		updateTopicsList(preUpdateEventData)
	end
	e.element:registerAfter("preUpdate", firstPreUpdate)
	e.element:registerAfter("update", update)
end
event.register("uiActivated", onDialogueMenuActivated, { filter = "MenuDialog" })

local function displayPlayerChoices()
	if (not common.config.displayPlayerDialogueChoices) then
		return
	end

	local menu = tes3ui.findMenu("MenuDialog")
	if not menu then
		return
	end

	local block = menu:findChild("MenuDialog_answer_block")
	if not block then
		return
	end

	for _, child in pairs(block.parent.children) do
		if child.name == "MenuDialog_answer_block" then
			child:registerBefore("mouseClick", function(e)
				tes3.messageBox(child.text)

				-- Find our newly created element and recolor it.
				local dialogueElements = block.parent.children
				local createdElement = dialogueElements[#dialogueElements]
				createdElement.color = tes3ui.getPalette("journal_finished_quest_over_color")
			end)
		end
	end
end
event.register("postInfoResponse", displayPlayerChoices)
