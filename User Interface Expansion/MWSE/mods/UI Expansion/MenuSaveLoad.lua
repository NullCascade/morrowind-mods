local common = require("UI Expansion.common")

local load_menu_id = tes3ui.registerID("MenuLoad")
local load_title_id = tes3ui.registerID("MenuLoad_savelabel")
local load_scroll_id = tes3ui.registerID("MenuLoad_SaveScroll")
local load_cancelButton_id = tes3ui.registerID("MenuLoad_Okbutton")
local load_charSelect_id = tes3ui.registerID("UIEXP_MenuLoad_CharSelect")

local save_menu_id = tes3ui.registerID("MenuSave")
local save_scroll_id = tes3ui.registerID("MenuSave_SaveScroll")
local save_saveButton_id = tes3ui.registerID("MenuSave_savegame")
local save_cancelButton_id = tes3ui.registerID("MenuSave_Cancelbutton")
local save_showAll_id = tes3ui.registerID("UIEXP_MenuSave_ShowAll")
local save_saveInput_id = tes3ui.registerID("UIEXP_MenuSave_SaveInput")

local function SaveFileName(saveName)
	-- Lowercase everything, strip non-alphanumeric characters.
	return string.format("%s_%s", tes3.mobilePlayer.object.name:lower(), saveName:lower()):gsub("%W", "")
end

local function CanSave(saveName)
	-- Don't have to check for max length, as it's limited by the text input.
	if (#saveName > 0) then
		return true
	end

	return false
end

local function SaveExists(saveName, saveFilename)
	for file in lfs.dir("saves") do
		if (saveFilename) then
			if (file == saveFilename) then
				return true
			end
		elseif (string.endswith(file, ".ess") or string.endswith(file, ".tes")) then
			if (file:sub(0, -5) == SaveFileName(saveName)) then
				return true
			end
		end
	end

	return false
end

local function Save(saveName, saveFilename)
	tes3ui.findMenu(save_menu_id):destroy()
	tes3ui.leaveMenuMode()
	if (saveFilename) then
		tes3.saveGame({ file = saveFilename, name = saveName })
	else
		tes3.saveGame({ file = SaveFileName(saveName), name = saveName })
	end
end

local function TrySave(saveName, saveFilename)
	if (CanSave(saveName)) then
		if(SaveExists(saveName, saveFilename)) then
			tes3.messageBox({
				message = tes3.findGMST(tes3.gmst.sMessage4).value,
				buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
				callback = function(e)
					if (e.button == 0) then
						Save(saveName, saveFilename)
					end
				end
			})
		else
			Save(saveName)
		end
	end
end

-- Returns true if we filtered successfully, false if not.
local function filterGameFiles(scrollElement, characterName)
	local scrollKids = scrollElement:getContentElement().children

	local foundMatchingSave = false
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
				foundMatchingSave = true
			end
		end
	end

	-- Uh oh, make em all visible.
	if (not foundMatchingSave) then
		for i = 1, #scrollKids do
			scrollKids[i].visible = true
		end
		scrollElement.widget:contentsChanged()
		return false
	end

	scrollElement.widget:contentsChanged()
	return true
end

local function SetActive(listBoxElement, selected)
	local listKids = listBoxElement:getContentElement().children
	local foundStringMatch = false
	for i = 1, #listKids do
		if (listKids[i].widget) then
			listKids[i].widget.state = 1 -- Normal
			-- Trigger leave to encourage the element to change color properly.
			listKids[i]:triggerEvent("mouseLeave")

			if (type(selected) == "string" and listKids[i].text == selected) then
				listKids[i].widget.state = 4
				listKids[i]:triggerEvent("mouseLeave")
				foundStringMatch = true
			end
		end
	end

	if (type(selected) ~= "string") then
		selected.widget.state = 4 -- Active
	elseif (not foundStringMatch) then
		SetActive(listBoxElement, common.dictionary.allCharacters)
	end
end

-- Used during loading only.
local function MakeCharacterList(scrollElement, characterSelectElement)
	local scrollKids = scrollElement:getContentElement().children

	local characters = {}

	for i = 1, #scrollKids do
		local save = scrollKids[i]:getPropertyObject("MenuLoad_file", "tes3gameFile")

		-- Save game button will not have a game save property.
		if (save) then
			characters[save.playerName] = true
		end
	end

	for k, v in pairs(characters) do
		local select = characterSelectElement:createTextSelect({ text = k })
		select:register("mouseClick", function()
			filterGameFiles(scrollElement, k)
			SetActive(characterSelectElement, select)
		end)
	end
end

local function SetSaveGameEventHandlers(scrollElement, characterSelectElement)
	local scrollKids = scrollElement:getContentElement().children

	for i = 1, #scrollKids do
		local save = scrollKids[i]:getPropertyObject("MenuLoad_file", "tes3gameFile") or
		scrollKids[i]:getPropertyObject("MenuSave_file", "tes3gameFile")

		-- Save game button will not have a game save property.
		if (save) then
			-- Add an event so we can delete saves.
			scrollKids[i]:register("mouseClick", function()
				local inputController = tes3.worldController.inputController
				if (inputController:isKeyDown(tes3.scanCode.lShift) or inputController:isKeyDown(tes3.scanCode.rShift)) then
					tes3.messageBox({
						message = tes3.findGMST(tes3.gmst.sMessage3).value,
						buttons = { tes3.findGMST(tes3.gmst.sYes).value, tes3.findGMST(tes3.gmst.sNo).value },
						callback = function(e)
							if (e.button == 0) then
								save:deleteFile()
								scrollKids[i]:destroy()
								scrollElement.widget:contentsChanged()
								if (characterSelectElement) then
									MakeCharacterList(scrollElement, characterSelectElement)
								end
							end
						end
					})
				-- Reimplement saving/loading instead of forwarding the event.
				elseif (characterSelectElement) then
					tes3ui.findMenu(load_menu_id):destroy()
					tes3ui.leaveMenuMode()
					tes3.loadGame(save.filename)
				else
					TrySave(save.description, save.filename)
				end
			end)
			-- Edit tooltip.
			scrollKids[i]:register("help", function(e)
				e.source:forwardEvent(e)
				local tip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
				local m = scrollElement:getTopLevelMenu()
				if (tip) then
					-- Set image aspect to match screen aspect.
					local image = tip:findChild(tes3ui.registerID("image"))
					image.width = 180 * m.maxWidth / m.maxHeight
					image.height = 180
					tip:updateLayout()
				end
			end)
		end
	end

	if (characterSelectElement) then
		characterSelectElement:getContentElement():destroyChildren()
		local allChars = characterSelectElement:createTextSelect({ text = common.dictionary.allCharacters })
		allChars:register("mouseClick", function()
			filterGameFiles(scrollElement)
			SetActive(characterSelectElement, allChars)
		end)
		characterSelectElement:createDivider()

		characterSelectElement.widget:contentsChanged()
		SetActive(characterSelectElement, common.dictionary.allCharacters)
	end
end

local function menuLoad(e)
	if (e.newlyCreated) then
		e.element.width = 0.5 * e.element.maxWidth
		e.element.height = 0.6 * e.element.maxHeight

		local scroll = e.element:findChild(load_scroll_id)
		scroll.widthProportional = 1.5
		local panel = scroll.parent
		panel.flowDirection = "left_to_right"

		local charSelect = panel:createVerticalScrollPane({ id = load_charSelect_id })
		charSelect.widthProportional = 0.5
		charSelect.heightProportional = 1.0
		charSelect.borderRight = 4
		charSelect.paddingAllSides = 4

		-- Info on the left, saves on the right.
		panel:reorderChildren(0, -1, 1)

		-- Destroy the label since it's in the wrong block, but recreate it with the same ID.
		local badLabel = e.element:findChild(load_title_id)
		panel.parent:createLabel({ id = load_title_id, text = tes3.findGMST(tes3.gmst.sLoadGame).value })
		panel.parent:reorderChildren(0, -1, 1)
		badLabel:destroy()

		local cancelButton = e.element:findChild(load_cancelButton_id)
		cancelButton.borderAllSides = 0
		cancelButton.borderTop = 4
	end

	local scroll = e.element:findChild(load_scroll_id)
	local charSelect = e.element:findChild(load_charSelect_id)
	SetSaveGameEventHandlers(scroll, charSelect)
	MakeCharacterList(scroll, charSelect)

	if( tes3.mobilePlayer ~= nil ) then
		filterGameFiles(scroll, tes3.mobilePlayer.object.name)
		SetActive(charSelect, tes3.mobilePlayer.object.name)
	else
		filterGameFiles(scroll)
	end
end
event.register("uiActivated", menuLoad, { filter = "MenuLoad"})

local function menuSave(e)
	if (e.newlyCreated) then
		local scroll = e.element:findChild(save_scroll_id)
		e.element.width = 0.5 * e.element.maxWidth
		e.element.height = 0.6 * e.element.maxHeight

		scroll.widthProportional = 1.0

		local cancelButton = e.element:findChild(save_cancelButton_id)
		cancelButton.borderAllSides = 0
		cancelButton.borderTop = 4

		local buttonPanel = cancelButton.parent
		buttonPanel.childAlignX = -1.0
		buttonPanel.flowDirection = "left_to_right"

		local inputBlock = buttonPanel:createThinBorder()
		inputBlock.width = 400
		inputBlock.height = 21
		inputBlock.borderTop = 4
		inputBlock.borderRight = 4
		inputBlock.paddingLeft = 4
		inputBlock.paddingRight = 4
		inputBlock.childAlignY = 0.5
		local saveInput = inputBlock:createTextInput({ id = save_saveInput_id })
		saveInput.widget.lengthLimit = 31
		saveInput.text = tes3.mobilePlayer.cell.name or tes3.mobilePlayer.cell.region.name

		local oldSaveButton = scroll.parent:findChild(save_saveButton_id)
		oldSaveButton:destroy()
		-- Reuse the existing save button ID.
		local saveButton = buttonPanel:createButton({ id = save_saveButton_id, text = common.dictionary.save })
		saveButton:register("mouseClick", function()
			TrySave(saveInput.text)
		end)
		saveButton.borderAllSides = 0
		saveButton.borderTop = 4
		saveButton.borderRight = 4

		-- Now we can register events on the input
		saveInput:register("keyPress", function(x)
			x.source:forwardEvent(x)
			if (not CanSave(saveInput.text)) then
				saveButton.disabled = true
				saveButton.widget.state = 2 -- Disabled
			else
				saveButton.disabled = false
				saveButton.widget.state = 1 -- Normal
			end
		end)
		saveInput:register("keyEnter", function()
			TrySave(saveInput.text)
		end)
		saveInput:register("mouseClick", function()
			saveInput.text = saveInput.text .. "|"
			tes3ui.acquireTextInput(saveInput)
		end)
		inputBlock:register("mouseClick", function()
			saveInput.text = saveInput.text .. "|"
			tes3ui.acquireTextInput(saveInput)
		end)

		local showAll = buttonPanel:createButton({ id = save_showAll_id, text = common.dictionary.allCharacters })
		showAll:register("mouseClick", function()
			if (showAll.text == common.dictionary.allCharacters) then
				filterGameFiles(scroll)
				showAll.text = common.dictionary.currentCharacter
			else
				filterGameFiles(scroll, tes3.mobilePlayer.object.name)
				showAll.text = common.dictionary.allCharacters
			end
		end)
		showAll.borderAllSides = 0
		showAll.borderTop = 4

		buttonPanel:reorderChildren(0, -3, 3)
	end

	local scroll = e.element:findChild(save_scroll_id)
	SetSaveGameEventHandlers(scroll)

	local saveInput = e.element:findChild(save_saveInput_id)
	tes3ui.acquireTextInput(saveInput)

	if (tes3.mobilePlayer ~= nil) then
		if (not filterGameFiles(scroll, tes3.mobilePlayer.object.name)) then
			-- Account for a new character with no saves:
			local showAll = e.element:findChild(save_showAll_id)
			showAll.text = common.dictionary.currentCharacter
			showAll.widget.state = 2 -- Disabled
			showAll.disabled = true
		end
	else
		filterGameFiles(scroll)
	end
end
event.register("uiActivated", menuSave, { filter = "MenuSave" })