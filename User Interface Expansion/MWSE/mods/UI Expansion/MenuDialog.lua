
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

-- Adds number prefix to Choice answers and makes them working pressing the number key.
local answers = {}

local function checkForAnswerHotkey(e)
	-- Make sure we're in the dialogue menu.
	local topMenu = tes3.getTopMenu()
	if not topMenu then
		---mwse.log("checkForAnswerHotkey: topMenu = %s", topMenu)
		return
	end
	if not (topMenu.id == GUI_ID_MenuDialog) then
		---mwse.log("checkForAnswerHotkey: topMenu.id = %s, GUI_ID_MenuDialog = %s", topMenu.id, GUI_ID_MenuDialog)
		return
	end

	-- Make sure we have answers.
	if not answers then
		---mwse.log("checkForAnswerHotkey: answers = %s", answers)
		return
	end
	if #answers <= 0 then
		---mwse.log("checkForAnswerHotkey: #answers = %s", #answers)
		return
	end

	local key = tes3.scanCodeToNumber[e.keyCode]
	if not key then
		return
	end

	local answer = answers[key]
	if not answer then
		---mwse.log("checkForAnswerHotkey: key = %s, answer not found", key)
		return
	end

	if answer then
		local s = string.match(answer.text, "^%d+%. (.+)$")
		if not s then
			s = answer.txt
		end
		tes3.messageBox(s)
		answer:triggerEvent("mouseClick")
	end
end

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
			---mwse.log("updateTopicsList tes3ui.findMenu(GUI_ID_MenuDialog) == nil");
			answers = {}
			return
		end

		-- Make sure that the node heard from field is always used.
		if e.info then
			---mwse.log("[UI Expansion] e.info = %s", e.info);
			if e.actor then
				---mwse.log("[UI Expansion] e.actor = %s", e.actor);
				if (e.info.firstHeardFrom == nil) then
					if (textPane:findChild(GUI_ID_MenuDialog_answer_block) == nil) then
						e.info.firstHeardFrom = e.actor
					end
				end
				---mwse.log("[UI Expansion] e.info.firstHeardFrom = %s", e.info.firstHeardFrom)
			end
		end
	end

	-- Catch events from hyperlinks.
	for _, element in pairs(textPane.children) do
		---mwse.log("[UI Expansion] _ = %s, element = %s, element.id = %s, %s", _, element, element.id, element.text)
		if (element.id == GUI_ID_MenuDialog_hyper) then
			---mwse.log("[UI Expansion] GUI_ID_MenuDialog_hyper = element.id = %s, %s", element.id, element.text)
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
	---mwse.log( json.encode(textPane.children,{indent = true}) ) -- something is not right, it seems GUI_ID_MenuDialog_answer_block are not added on greeting /abot
end

local function update()

	--answers = {}

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
					node:register("mouseClick", updateTopicsList)
					answerIndex = answerIndex + 1
					if not string.match(oldText,"^%d+") then
						node.text = string.format("%d. %s", answerIndex, oldText)
						answers[answerIndex] = node
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
		---mwse.log("GUI_ID_MenuDialog_hyper = %s, GUI_ID_MenuDialog_answer_block = %s", GUI_ID_MenuDialog_hyper, GUI_ID_MenuDialog_answer_block)
		local scroll_pane = menuDialog:findChild(GUI_ID_MenuDialog_scroll_pane)
		if scroll_pane then
			local pane_pane = scroll_pane:findChild(GUI_ID_PartScrollPane_pane)
			if pane_pane then
				traverse(pane_pane)
				--[[
				local path = traverse(pane_pane)
				local s = json.encode(path,{indent = true})
				mwse.log("scroll_pane:")
				mwse.log(s)
				--]]
			end
		end

	end
end

local function onDialogueMenuActivated(e)
	-- We only care if this is the node time it was activated.
	if (not e.newlyCreated) then
		return
	end

	-- Set the pre-update event to update the topic list.
	e.element:register("preUpdate", function(preUpdateEventData)
		-- We only want this event to fire once. We'll manually track changes above to be more efficient.
		e.element:unregister("preUpdate")
		updateTopicsList(preUpdateEventData)
	end)

	-- special as I am not able to find GUI_ID_MenuDialog_answer_block in pairs(children) on greetings /abot
	answers = {}
	e.element:register("update", update)

end
event.register("uiActivated", onDialogueMenuActivated, { filter = "MenuDialog" })
event.register("keyDown", checkForAnswerHotkey)
