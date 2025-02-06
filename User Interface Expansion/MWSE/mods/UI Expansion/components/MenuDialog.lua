local config = require("UI Expansion.config")
local common = require("UI Expansion.lib.common")
local log = require("UI Expansion.log")

local MenuDialog = {}
local internal = {}

--
-- Internal module
--

--- Called after an MenuDialog_answer_block element is clicked.
--- @param e tes3uiEventData
function internal.onAnswerClicked(e)
	tes3.messageBox(e.source.text)

	-- Find our newly created element and recolor it.
	local dialogueElements = e.source.parent.parent.children
	local createdElement = dialogueElements[#dialogueElements]
	createdElement.color = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)
end

--- If enabled, hooks into answers so that when they are clicked, it adds them to the dialogue.
function internal.displayPlayerDialogueChoices()
	if (not config.displayPlayerDialogueChoices) then return end

	local menu = MenuDialog.get()
	if (not menu) then return end

	local firstAnswer = menu:findChild("MenuDialog_answer_block")
	if (not firstAnswer) then return end

	for _, child in ipairs(firstAnswer.parent.children) do
		if (child.name == "MenuDialog_answer_block") then
			child:registerBefore(tes3.uiEvent.mouseClick, internal.onAnswerClicked)
		end
	end
end

--- Add numbers to the dialog choices.
function internal.updateAnswerText()
	local menuDialog = MenuDialog.get()
	if (not menuDialog) then return end

	local firstAnswer = menuDialog:findChild("MenuDialog_answer_block")
	if (not firstAnswer) then
		return
	end

	local answerCount = 0
	for _, child in ipairs(firstAnswer.parent.children) do
		if (child.name == "MenuDialog_answer_block") then
			answerCount = answerCount + 1

			local didBefore = child:getLuaData("UIExpansion:ChoiceNumbered")
			if (not didBefore) then
				child:setLuaData("UIExpansion:ChoiceNumbered", true)
				child:setLuaData("UIExpansion:KeyIndex", answerCount)
				child.text = string.format("%d. %s", answerCount, child.text)
			end
		end
	end
end

--- Check to see if the player has used a number key to select a response.
--- @param e keyDownEventData
function internal.checkForAnswerHotkey(e)
	-- Make sure we're in the dialogue menu.
	local menuDialog = tes3.getTopMenu()
	if not menuDialog or menuDialog.name ~= "MenuDialog" then
		return
	end

	-- Make sure we're not doing text input.
	if (common.isTextInputActive()) then
		return
	end

	-- Translate the key into a number.
	local key = tes3.scanCodeToNumber[e.keyCode]
	if not key then
		return
	end

	-- Do we have any answers?
	local firstAnswer = menuDialog:findChild("MenuDialog_answer_block")
	if not firstAnswer then
		return
	end

	-- Look for a child with a matching key and pretend we clicked it.
	for _, child in ipairs(firstAnswer.parent.children) do
		if (child:getLuaData("UIExpansion:KeyIndex") == key) then
			child:triggerEvent(tes3.uiEvent.mouseClick)
			return
		end
	end
end

--- Colors an individual topic textSelect element.
--- @param element tes3uiElement
function internal.updateTopic(element)
	-- Get the info associated with this topic.
	local menuDialog = element:getTopLevelMenu()
	local widget = element.widget --- @type tes3uiTextSelect
	local mobile = menuDialog:getPropertyObject("PartHyperText_actor") --- @type tes3mobileNPC|tes3mobileCreature
	local dialogue = element:getPropertyObject("PartHyperText_dialog") --- @type tes3dialogue
	local info = dialogue:getInfo({ actor = mobile })
	local actor = mobile.reference.baseObject

	-- Update color scheme on the topic.
	if (info.firstHeardFrom) then
		widget.idleDisabled = common.getColor(common.config.dialogueTopicSeenColor)
		widget.state = tes3.uiState.disabled
	elseif (info.actor == actor) then
		-- Topic has actor-unique dialogue, set new state.
		widget.idleActive = common.getColor(common.config.dialogueTopicUniqueColor)
		widget.state = tes3.uiState.active
	else
		widget.state = tes3.uiState.normal
	end
end

--- Loops through all dialogue topics, and colors them.
function internal.updateTopics()
	local menuDialog = MenuDialog.get()
	if (not menuDialog) then return end

	-- Go through and update all the topics.
	local topicsPane = menuDialog:findChild("MenuDialog_a_topic").parent
	for _, element in ipairs(topicsPane.children) do
		-- We only care about topics in this list.
		if (element.name == "MenuDialog_a_topic") then
			internal.updateTopic(element)
		end
	end
end

--- Called when the topics list is recreated.
function internal.onTopicsListUpdated()
	-- Because variables can invalidate the list on the first frame of dialogue, we want to delay this by one frame.
	timer.frame.delayOneFrame(internal.updateTopics)
end

--- This event fires immediately after a dialogue response is processed. We use it to make sure that the firstHeardFrom
--- field is properly assigned. We also use it to show player dialogue choices.
--- @param e postInfoResponseEventData
function internal.onPostInfoResponse(e)
	local menuDialog = MenuDialog.get()
	if (not menuDialog) then return end

	-- Update the last clicked dialogue info to force the last heard from field.
	if (e.info.firstHeardFrom == nil) then
		local mobile = menuDialog:getPropertyObject("PartHyperText_actor") --- @type tes3mobileNPC|tes3mobileCreature
		e.info.firstHeardFrom = mobile.reference.baseObject
		e.info.modified = true
	end

	-- We also use this time to update answer text to add callbacks/numbering.
	internal.updateAnswerText()

	-- If it was a choice, display it.
	internal.displayPlayerDialogueChoices()
end


--
-- Public module
--

--- Gets the dialogue menu.
--- @return tes3uiElement?
function MenuDialog.get()
	return tes3ui.findMenu("MenuDialog")
end

--- Determines if this component is active.
--- @type boolean
internal.hooked = false

--- Enables this component.
function MenuDialog.hook()
	if (internal.hooked) then return end

	-- Set up events.
	event.register(tes3.event.keyDown, internal.checkForAnswerHotkey)
	event.register(tes3.event.postInfoResponse, internal.onPostInfoResponse)
	event.register(tes3.event.topicsListUpdated, internal.onTopicsListUpdated)

	internal.hooked = true
end

--- Disables this component.
function MenuDialog.unhook()
	if (not internal.hooked) then return end

	-- Clean up events.
	event.unregister(tes3.event.keyDown, internal.checkForAnswerHotkey)
	event.unregister(tes3.event.postInfoResponse, internal.onPostInfoResponse)
	event.unregister(tes3.event.topicsListUpdated, internal.onTopicsListUpdated)

	internal.hooked = false
end

return MenuDialog