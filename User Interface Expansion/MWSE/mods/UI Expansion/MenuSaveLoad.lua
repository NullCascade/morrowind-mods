local common = require("UI Expansion.common")

local function filterGameFiles(scrollElement, characterName)
	local scrollKids = scrollElement:getContentElement().children

	for i = 1, #scrollKids do
		local save = scrollKids[i]:getPropertyObject("MenuLoad_file", "tes3gameFile") or
		scrollKids[i]:getPropertyObject("MenuSave_file", "tes3gameFile")

		-- Save game button will not have a game save property.
		if (save) then
			if (characterName ~= nil and characterName ~= save.playerName) then
				scrollKids[i].visible = false
			else
				scrollKids[i].visible = true
				scrollKids[i].text = string.format("%s, Day %u: %s",
				save.playerName, save.daysPassed, save.description)
			end
		end
	end

	scrollElement.widget:contentsChanged()
end

local function SetActive(listBoxElement, selected)
	local listKids = listBoxElement:getContentElement().children
	for i = 1, #listKids do
		if (listKids[i].widget) then
			listKids[i].widget.state = 1 -- Normal
			-- Trigger leave to encourage the element to change color properly.
			listKids[i]:triggerEvent("mouseLeave")

			if (type(selected) == "string" and listKids[i].text == selected) then
				listKids[i].widget.state = 4
				listKids[i]:triggerEvent("mouseLeave")
			end
		end
	end

	if (type(selected) ~= "string") then
		selected.widget.state = 4 -- Active
	end
end

local function FindCharacters(scrollElement, characterSelectElement)
	local scrollKids = scrollElement:getContentElement().children

	local characters = {}

	for i = 1, #scrollKids do
		local save = scrollKids[i]:getPropertyObject("MenuLoad_file", "tes3gameFile") or
		scrollKids[i]:getPropertyObject("MenuSave_file", "tes3gameFile")

		-- Save game button will not have a game save property.
		if (save) then
			characters[save.playerName] = true
		end
	end

	for k, v in pairs(characters) do
		local select = characterSelectElement:createTextSelect({ text = k })
		select:register("mouseClick", function(e)
			filterGameFiles(scrollElement, k)
			SetActive(characterSelectElement, select)
		end)
	end

	characterSelectElement.widget:contentsChanged()
	SetActive(characterSelectElement, common.dictionary.allCharacters)
end

local load_title_id = tes3ui.registerID("MenuLoad_savelabel")
local load_scroll_id = tes3ui.registerID("MenuLoad_SaveScroll")
local load_charSelect_id = tes3ui.registerID("UIEXP_MenuLoad_CharSelect")

local function menuLoad(e)
	if (e.newlyCreated) then
		e.element.width = 600

		local scroll = e.element:findChild(load_scroll_id)
		scroll.widthProportional = 1.2
		local panel = scroll.parent
		panel.flowDirection = "left_to_right"

		local charSelect = panel:createVerticalScrollPane({ id = load_charSelect_id })
		charSelect.widthProportional = 0.8
		charSelect.heightProportional = 1.0
		charSelect.borderRight = 4
		charSelect.paddingAllSides = 4
		local allChars = charSelect:createTextSelect({ text = common.dictionary.allCharacters })
		allChars:register("mouseClick", function(e)
			filterGameFiles(scroll)
			SetActive(charSelect, allChars)
		end)
		charSelect:createDivider()

		-- Info on the left, saves on the right.
		panel:reorderChildren(0, -1, 1)

		-- Destroy the label since it's in the wrong block, but recreate it with the same ID.
		local badLabel = e.element:findChild(load_title_id)
		panel.parent:createLabel({ id = load_title_id, text = tes3.findGMST(tes3.gmst.sLoadGame).value })
		panel.parent:reorderChildren(0, -1, 1)
		badLabel:destroy()
	end

	local scroll = e.element:findChild(load_scroll_id)
	local charSelect = e.element:findChild(load_charSelect_id)
	FindCharacters(scroll, charSelect)

	if( tes3.mobilePlayer ~= nil ) then
		filterGameFiles(scroll, tes3.mobilePlayer.object.name)
		SetActive(charSelect, tes3.mobilePlayer.object.name)
	else
		filterGameFiles(scroll)
	end
end
event.register("uiActivated", menuLoad, { filter = "MenuLoad"})

local save_scroll_id = tes3ui.registerID("MenuSave_SaveScroll")
local save_saveButton_id = tes3ui.registerID("MenuSave_savegame")
local save_cancelButton_id = tes3ui.registerID("MenuSave_Cancelbutton")

local function menuSave(e)
	if (e.newlyCreated) then
		local scroll = e.element:findChild(save_scroll_id)
		e.element.width = 600

		scroll.widthProportional = 1.0

		local cancelButton = e.element:findChild(save_cancelButton_id)

		local saveButton = scroll.parent:findChild(save_saveButton_id)
		saveButton.visible = false
		local newSaveButton = cancelButton.parent:createButton({ text = tes3.findGMST(tes3.gmst.sSaveMenu1).value })
		newSaveButton:register("mouseClick", function(e)
			saveButton:triggerEvent("mouseClick")
		end)
		cancelButton.parent.flowDirection = "left_to_right"
		cancelButton.parent:reorderChildren(0, -1, 1)
	end

	local scroll = e.element:findChild(save_scroll_id)
	if( tes3.mobilePlayer ~= nil ) then
		filterGameFiles(scroll, tes3.mobilePlayer.object.name)
	else
		filterGameFiles(scroll)
	end
end
event.register("uiActivated", menuSave, { filter = "MenuSave"})