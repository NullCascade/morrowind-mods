local common = require("UI Expansion.common")
local lastTarget

local id_serviceList = tes3ui.registerID("MenuServiceTraining_ServiceList")
local id_pane = tes3ui.registerID("PartScrollPane_pane")

local id_cancel = tes3ui.registerID("UIEXP_MenuTraining_Cancel")
local id_skill_1 = tes3ui.registerID("UIEXP_MenuTraining_Skill1")
local id_skill_2 = tes3ui.registerID("UIEXP_MenuTraining_Skill2")
local id_skill_3 = tes3ui.registerID("UIEXP_MenuTraining_Skill3")
local id_gold = tes3ui.registerID("UIEXP_MenuTraining_Gold")

local function onAfterTrainTimer()
	if (lastTarget ~= nil and tes3.getPlayerTarget() == lastTarget) then
		tes3.player:activate(lastTarget)
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
		local trainbtn = menu:findChild(tes3ui.registerID("MenuDialog_service_training"))
		trainbtn:triggerEvent("mouseClick")
	end
end

local function menuTraining(e)
	lastTarget = tes3ui.getServiceActor().reference
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	menu.visible = false
end

event.register("uiActivated", menuTraining, { filter = "MenuServiceTraining"})

local function expertiseText(skill)
	for i = 4, 0, -1 do
		if (skill >= 25 * i) then
			return common.dictionary.expertiseLevels[i+1]
		end
	end
end


local ImageButton = {}

function ImageButton.over(e)
	if (not e.widget.disabled) then
		e.widget.color = { 1.0, 1.0, 1.0 }
		e.widget.children[1].alpha = 0.85
		e.widget:getTopLevelParent():updateLayout()
	end
end

function ImageButton.leave(e)
	if (not e.widget.disabled) then
		e.widget.color = { 0, 0, 0 }
		e.widget.children[1].alpha = 1.0
		e.widget:getTopLevelParent():updateLayout()
	end
end

function ImageButton.press(e)
	if (not e.widget.disabled) then
		e.widget.color = { 1.0, 1.0, 0.7 }
		e.widget.children[1].alpha = 0.8
		e.widget:getTopLevelParent():updateLayout()
		tes3.worldController.menuClickSound:play()
	end
end

function ImageButton.release(e)
	if (not e.widget.disabled) then
		e.widget.color = { 0, 0, 0 }
		e.widget.children[1].alpha = 1.0
		e.widget:getTopLevelParent():updateLayout()
	end

	e.widget:triggerEvent(e)
end


function ImageButton.create(parent, imagePath, w, h)
	local background = parent:createRect{}
	background.width = w
	background.height = h
	background:setPropertyBool("is_part", true)

	local im = background:createImage{ path = imagePath }
	im.width = w
	im.height = h
	im.scaleMode = true

	im:register("mouseOver", ImageButton.over)
	im:register("mouseLeave", ImageButton.leave)
	im:register("mouseDown", ImageButton.press)
	im:register("mouseRelease", ImageButton.release)
	im:register("mouseClick", ImageButton.release)

	return background
end

local function onClickTrainSkill(e)
	if (e.source.disabled) then
		return
	end

	local menu = e.widget:getTopLevelParent()
	local list = menu:findChild(id_serviceList)
	local i = e.widget:getPropertyInt("UIEXP_ListIndex")
	local s = list:findChild(id_pane).children[i].children[1]
	s:triggerEvent(e)
	
	timer.start({ duration = 1, callback = onAfterTrainTimer })
end

local function createTrainSkillElement(parent, id, data)
	local train = parent:createBlock{id = id}
	train.width = 180
	train.autoHeight = true
	train.flowDirection = "top_to_bottom"

	local border = train:createThinBorder{}
	border.autoWidth = true
	border.paddingAllSides = 4
	border.absolutePosAlignX = 0.5

	local skillIconPath = data.skill.iconPath:gsub("\\k\\", "\\rfd\\")
	if not lfs.attributes("data files/" .. skillIconPath) then
		skillIconPath = data.skill.iconPath
	end

	local button = ImageButton.create(border, string.format("icons/ui_exp/skillbg_%s.dds", tes3.specializationName[data.skill.specialization]), 128, 128)
	button:setPropertyInt("UIEXP_ListIndex", data.forward)
	button:register("mouseClick", onClickTrainSkill)
	local skillIcon = border:createImage{path = skillIconPath}
	skillIcon.consumeMouseEvents = false
	skillIcon.absolutePosAlignX = 0.5
	skillIcon.absolutePosAlignY = 0.5

	-- Unpleasant hack:
	border.height = 136

	local canAfford = data.cost <= tes3.getPlayerGold()
	local level = tes3.mobilePlayer.skills[data.skill.id+1]
	local attr = tes3.mobilePlayer.attributes[data.skill.attribute+1]
	local trainerLevel = trainer.skills[data.skill.id+1]

	local textColor = (canAfford and level.base < attr.base and level.base < trainerLevel.base) and tes3ui.getPalette("normal_color") or tes3ui.getPalette("disabled_color")

	local temp
	temp = train:createLabel{ text = data.skill.name }
	temp.borderTop = 18
	temp.color = textColor
	temp.absolutePosAlignX = 0.5
	-- Stretch goal:
	--[[
	temp:register("help", function()
		local tip = tes3ui.createTooltipMenu()
		tip:createLabel{text = "skill tooltip"}
	end)
	]]

	temp = train:createLabel{ text = string.format("%s %s", expertiseText(trainerLevel.base), common.dictionary.trainer) }
	temp.borderTop = 6
	temp.color = textColor
	temp.absolutePosAlignX = 0.5

	local text
	if (level.base < attr.base and level.base < trainerLevel.base) then
		text = string.format(common.dictionary.trainTo, level.base + 1)
	else
		if (level.base >= trainerLevel.base) then
			text = common.dictionary.trainerLimit
		else
			text = tes3.findGMST(tes3.gmst.sAttributeStrength + data.skill.attribute).value
			text = string.format(common.dictionary.attributeLimit, text, level.base)
		end
		textColor = tes3ui.getPalette("negative_color")
		button.disabled = true
		button.color = { 0, 0, 0 }
		button.children[1].alpha = 0.25
	end

	temp = train:createLabel{ text = text }
	temp.borderTop = 40
	temp.color = textColor
	temp.wrapText = true
	temp.justifyText = tes3.justifyText.center

	if (level.base < trainerLevel.base) then
		temp = train:createLabel{ text = string.format("%d %s", data.cost, common.dictionary.goldAbbr) }
		temp.borderTop = 8
		temp.color = canAfford and tes3ui.getPalette("normal_color") or tes3ui.getPalette("negative_color")
		temp.absolutePosAlignX = 0.5
	end

	if (not canAfford) then
		button.disabled = true
		button.color = { 0, 0, 0 }
		button.children[1].alpha = 0.25
	end
end


local function onCancel(e)
	local menu = e.source:getTopLevelParent()
	local ok = menu:findChild(tes3ui.registerID("MenuServiceTraining_Okbutton"))
	ok:triggerEvent(e)
end

local function modifyWindow(menu)
	local list = menu:findChild(id_serviceList)

	local debug = false
	if (debug) then
		-- Keep listbox visible
		list.autoHeight = false
		list.height = 120
		list.layoutHeightFraction = -1
	else
		-- Hide existing UI
		for _, v in pairs(list.parent.children) do
			v.visible = false
		end
	end

	-- Scrape data
	trainer = menu:getPropertyObject("MenuServiceTraining_Actor")
	training = {}
	for i,v in ipairs(list:findChild(id_pane).children) do
		training[i] = {}
		training[i].skill = tes3.getSkill(v:getPropertyInt("MenuServiceTraining_ListNumber"))
		training[i].cost = tonumber(string.match(v.children[1].text, " - (%d+)"))
		training[i].forward = i
	end

	-- Remake layout
	menu.autoWidth = true
	menu.autoHeight = true

	local title = menu:createLabel{ text = tes3.findGMST("sTrainingServiceTitle").value }
	title.parent.paddingLeft = 24
	title.parent.paddingRight = 24
	title.parent.childAlignX = 0.5  -- centre content alignment
	title.borderTop = 15
	title.borderBottom = 45
	title.color = tes3ui.getPalette("header_color")

	local skills_block = menu:createBlock{}
	skills_block.autoWidth = true
	skills_block.autoHeight = true
	skills_block.flowDirection = "left_to_right"

	createTrainSkillElement(skills_block, id_skill_1, training[1])
	createTrainSkillElement(skills_block, id_skill_2, training[2])
	createTrainSkillElement(skills_block, id_skill_3, training[3])

	local button_block = menu:createBlock{}
	button_block.borderTop = 75
	button_block.layoutWidthFraction = 1.0  -- width is 100% parent width
	button_block.autoHeight = true

	local temp = button_block:createLabel{id = id_gold}
	temp.text = string.format("%s: %d %s",tes3.findGMST(tes3.gmst.sGold).value, tes3.getPlayerGold(), common.dictionary.goldAbbr)

	local button_cancel = button_block:createButton{id = id_cancel, text = tes3.findGMST("sDone").value}
	button_cancel.layoutOriginFractionX = 1.0
	button_cancel:register("mouseClick", onCancel)

	-- Final setup
	menu:getTopLevelParent():updateLayout()
end

local function onTraining(e)
	if (e.newlyCreated) then
		modifyWindow(e.element)
	end
end
event.register("uiActivated", onTraining, { filter = "MenuServiceTraining" })