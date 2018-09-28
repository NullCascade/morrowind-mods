
local GUI_ID_MenuDialog = tes3ui.registerID("MenuDialog")
local GUI_ID_MenuDialog_a_topic = tes3ui.registerID("MenuDialog_a_topic")
local GUI_ID_MenuDialog_divider = tes3ui.registerID("MenuDialog_divider")
local GUI_ID_MenuDialog_hyper = tes3ui.registerID("MenuDialog_hyper")
local GUI_ID_MenuDialog_scroll_pane = tes3ui.registerID("MenuDialog_scroll_pane")
local GUI_ID_MenuDialog_topics_pane = tes3ui.registerID("MenuDialog_topics_pane")

local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

local GUI_Palette_Active = tes3ui.getPalette("active_color")
local GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")

local common = require("UI Expansion.common")

InputController = tes3.worldController.inputController

----------------------------------------------------------------------------------------------------
-- Dialogue: 
----------------------------------------------------------------------------------------------------

local this = {}

local topicCount = 0

function this.modifyNewHypertext(textPane, lastCount)
	local childCount = #textPane.children
	for i = lastCount + 1, childCount, 1 do
		local element = textPane.children[i]
		if (element.id == GUI_ID_MenuDialog_hyper) then
			element:register("mouseClick", this.onHyperlinkClicked)
		end
	end
end

function this.onHyperlinkClicked(e)
	local menuDialog = tes3ui.findMenu(GUI_ID_MenuDialog)
	local topics = menuDialog:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)
	local textPane = menuDialog:findChild(GUI_ID_MenuDialog_scroll_pane):findChild(GUI_ID_PartScrollPane_pane)

	local childCountBefore = #textPane.children

	-- Topic widget may be destroyed by the event
	e.source:forwardEvent(e)

	local dialogue = menuDialog:getPropertyObject("PartHyperText_dialog")
	this.modifyNewHypertext(textPane, childCountBefore)

	-- Set clicked topic to disabled
	for _, element in pairs(textPane.children) do
		local dialog = element:getPropertyObject("PartHyperText_dialog")
		if (dialog == dialogue) then
			if (element.widget.state == 1) then
				element.widget.state = 2
			end
			break
		end
	end
end

function this.onTopic(e)
	-- Set clicked topic to disabled
	e.source.widget.state = 2

	local menuDialog = tes3ui.findMenu(GUI_ID_MenuDialog)
	local textPane = menuDialog:findChild(GUI_ID_MenuDialog_scroll_pane):findChild(GUI_ID_PartScrollPane_pane)

	-- Topic widget may be destroyed by the event
	local n = #textPane.children
	e.source:forwardEvent(e)
	this.modifyNewHypertext(textPane, n)
end

function this.updateTopicList(e)
	local menuDialog = e.source
	local topics = menuDialog:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)
	local textPane = menuDialog:findChild(GUI_ID_MenuDialog_scroll_pane):findChild(GUI_ID_PartScrollPane_pane)

	-- Skip update if no new topics. May rarely be wrong if topics removed == topics added.
	local topicsChildren = topics.children
	local currentTopicCount = #topicsChildren
	if (topicCount == currentTopicCount) then
		return
	end
	topicCount = currentTopicCount

	-- Catch events from hyperlinks
	for _, element in pairs(textPane.children) do
		if (element.id == GUI_ID_MenuDialog_hyper) then
			element:register("mouseClick", this.onHyperlinkClicked)
		end
	end

	local mobileActor = menuDialog:getPropertyObject("PartHyperText_actor")
	local actor = mobileActor.reference.object.baseObject

	local paletteTopicSeen = common.config.palettes.dialogueTopicSeen
	local paletteTopicUnique = common.config.palettes.dialogueTopicUnique

	for _, element in pairs(topics.children) do
		if (element.id == GUI_ID_MenuDialog_a_topic) then
			element.widget.idleDisabled = paletteTopicSeen

			local dialogue = element:getPropertyObject("PartHyperText_dialog")
			local info = dialogue:getInfo({ actor = mobileActor })
			if (info == nil or info.firstHeardFrom) then
				element.widget.state = 2
			elseif (info.actor == actor) then
				-- Topic has actor-unique dialogue, set new state.
				element.widget.state = 4
				element.widget.idleActive = paletteTopicUnique
			else
				element.widget.state = 1
			end
			element:triggerEvent("mouseLeave")
			
			-- Catch events from topics
			element:register("mouseClick", function(mouseClickEventData)
				this.onTopic(mouseClickEventData)

				-- Work around an issue where certain topics in the engine would not preserve their first heard actor.
				if (info and not info.firstHeardFrom) then
					info.firstHeardFrom = actor
				end
			end)
		end
	end
end

function this.onMenuDialogActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local menuDialog = e.element
	local topics = menuDialog:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)

	topicCount = #topics.children
	menuDialog:register("preUpdate", this.updateTopicList)
end
event.register("uiActivated", this.onMenuDialogActivated, { filter = "MenuDialog" })
