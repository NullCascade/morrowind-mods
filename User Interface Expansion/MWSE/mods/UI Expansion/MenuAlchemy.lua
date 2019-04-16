local common = require("UI Expansion.common")
local id_alchemy_create_all_button = tes3ui.registerID("UIEXP_MenuAlchemy_create_all_button")
local id_alchemy_quantity_input = tes3ui.registerID("UIEXP_MenuAlchemy_quantity_input")
local id_alchemy_cancel_button = tes3ui.registerID("UIEXP_MenuAlchemy_cancel_button")

local brewCount = 0

local function onCreateAll(e)
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
	local createbtn = menu.children[2].children[3].children[1]
	local quantiyinp = 	menu.children[2].children[3].children[4].children[1]
	local quantity = quantiyinp.text
	brewCount = 0
	if(tonumber(quantity) ~= nil) then
		for i=1,tonumber(quantity) do createbtn:triggerEvent("mouseClick") end
	else
		tes3.messageBox{ message =  "Quantity is Not a Number" }
	end
	tes3.messageBox{ message =  "You have Successfuly Brewed:  " .. brewCount .. "  potion(s)" }
end

local function onCancel(e)
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
	local createbtn = menu.children[2].children[3].children[1]
	local cancelbtn = menu.children[2].children[3].children[2]
	cancelbtn:triggerEvent("mouseClick") 
end

local function menuAlchemy(e)
	local buttonLayout = e.element.children[2].children[3]
	local createbtn = e.element.children[2].children[3].children[1]
	local cancelbtn = e.element.children[2].children[3].children[2]
	local nameInput = e.element.children[2].children[1].children[2].children[1]
	local nameBorder = e.element.children[2].children[1].children[2]
	createbtn.visible = false
	cancelbtn.visible = false
	local cancelbtn = e.element.children[2].children[3].children[2]
	local input_label = buttonLayout:createLabel{ text = "Quantity:" }
    --input_label.borderBottom = 5
	local inputBorder = buttonLayout:createThinBorder{}
	inputBorder.heightProportional = 1.0
	inputBorder.autoWidth = true
	inputBorder.minWidth = 50
	inputBorder.borderAllSides = 2
    inputBorder.childAlignX = 0.5
    inputBorder.childAlignY = 0.5
	local input = inputBorder:createTextInput{ id = id_alchemy_quantity_input }
	input.borderLeft = 5
    input.borderRight = 5
    input.widget.lengthLimit = 10
	input.widget.eraseOnFirstKey = true
	input.justifyText = center
	input.text = tostring(common.config.alchemyDefaultQuantity)
	local buttonCreate = buttonLayout:createButton{id = id_alchemy_create_all_button, text = "Create"}
	local buttonCancel = buttonLayout:createButton{ id = id_alchemy_cancel_button, text = "Cancel"}

	buttonCreate:register("mouseClick", onCreateAll)
	buttonCancel:register("mouseClick", onCancel)

	input:register("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)
	nameInput:register("mouseClick", function()
		tes3ui.acquireTextInput(nameInput)
	end)
	inputBorder:register("mouseClick", function()
		tes3ui.acquireTextInput(input)
	end)
	nameBorder:register("mouseClick", function()
		tes3ui.acquireTextInput(nameInput)
	end)
end

function onBrew(e)
	brewCount = brewCount+1
end

event.register("uiActivated", menuAlchemy, { filter = "MenuAlchemy"})
event.register("potionBrewed", onBrew)