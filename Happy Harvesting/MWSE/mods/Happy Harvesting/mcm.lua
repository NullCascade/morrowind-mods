local this = {}

local refreshActiveList

local blackListPane
local blackListActualPane

local function createBlackListRow(container, id)
	local row = container:createBlock({})
	row.layoutWidthFraction = 1.0
	row.autoHeight = true
	blackListActualPane = row.parent

	local label = row:createLabel({ text = id })

	local removeBtn = row:createButton({ text = "Remove" })
	removeBtn.layoutOriginFractionX = 1.0
	removeBtn:register("mouseClick", function(e)
		table.removevalue(this.config.blacklist, id)
		row:destroy()
		refreshActiveList()
		container:getTopLevelParent():updateLayout()
	end)

	return row
end

local function caseInsensitiveSorter(a, b)
	return string.lower(a) < string.lower(b)
end

local function refreshBlackList()
	if (blackListActualPane) then
		blackListActualPane:destroyChildren()
	end
	table.sort(this.config.blacklist, caseInsensitiveSorter)
	for i = 1, #this.config.blacklist do
		createBlackListRow(blackListPane, this.config.blacklist[i])
	end
end

local activeListPane
local activeListActualPane

local function createActiveListRow(container, id)
	local row = container:createBlock({})
	row.layoutWidthFraction = 1.0
	row.autoHeight = true
	activeListActualPane = row.parent

	local label = row:createLabel({ text = id })

	if (table.find(this.config.blacklist, id) == nil) then
		local removeBtn = row:createButton({ text = "Blacklist" })
		removeBtn.layoutOriginFractionX = 1.0
		removeBtn:register("mouseClick", function(e)
			table.insert(this.config.blacklist, id)
			refreshBlackList()
			removeBtn.visible = false
		end)
	end

	return row
end

refreshActiveList = function()
	if (activeListActualPane) then
		activeListActualPane:destroyChildren()
    end
    
    local nearbyContainers = {}

	local player = tes3.player
    if (player) then
        local playerPos = player.position
		for containerRef in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
			local object = containerRef.object
			if (object.isInstance) then
				object = object.baseObject
			end

			if (object.organic == true and object.script == nil and tes3.getOwner(containerRef) == nil and containerRef.position:distance(playerPos) < 1000) then
                nearbyContainers[object] = true
            end
        end
    end
    
    local nearbyContainersArray= {}
    for k, v in pairs(nearbyContainers) do
        table.insert(nearbyContainersArray, k.id)
    end
    table.sort(nearbyContainersArray, caseInsensitiveSorter)

    for i = 1, #nearbyContainersArray do
        createActiveListRow(activeListPane, nearbyContainersArray[i])
    end
end

function this.onCreate(parent)
	blackListActualPane = nil
	activeListActualPane = nil

	local container = parent:createThinBorder({})
	container.flowDirection = "top_to_bottom"
	container.layoutHeightFraction = 1.0
	container.layoutWidthFraction = 1.0
	container.paddingAllSides = 6

	local descriptionLabel
	if (tes3.mobilePlayer) then
		descriptionLabel = container:createLabel({ text = "Happy Harvesting allows the quick looting of organic, unscripted containers. Some containers should be ignored by the system. Containers to ignore can be configured using the blacklist below." })
	else
		descriptionLabel = container:createLabel({ text = "Happy Harvesting allows the quick looting of organic, unscripted containers. Some containers should be ignored by the system. Containers to ignore can be configured using the blacklist below. When a game is loaded, nearby containers will also be shown to add them to the blacklist." })
	end
	descriptionLabel.layoutWidthFraction = 1.0
	descriptionLabel.wrapText = true
	descriptionLabel.layoutHeightFraction = -1
	descriptionLabel.borderBottom = 12

	local splitPane = container:createBlock({})
	splitPane.flowDirection = "left_to_right"
	splitPane.layoutWidthFraction = 1.0
	splitPane.layoutHeightFraction = 1.0
	splitPane.borderTop = 12

	do
		local blackListBox = splitPane:createBlock({})
		blackListBox.flowDirection = "top_to_bottom"
		blackListBox.layoutWidthFraction = 1.0
		blackListBox.layoutHeightFraction = 1.0
	
		local label = blackListBox:createLabel({ text = "Blacklist:" })
		label.borderBottom = 6

		blackListPane = blackListBox:createVerticalScrollPane({})
		blackListPane.layoutWidthFraction = 1.0
		blackListPane.layoutHeightFraction = 1.0
		blackListPane.paddingAllSides = 6

		refreshBlackList()
	end

	if (tes3.mobilePlayer) then
		local activeListBox = splitPane:createBlock({})
		activeListBox.flowDirection = "top_to_bottom"
		activeListBox.layoutWidthFraction = 1.0
		activeListBox.layoutHeightFraction = 1.0
		activeListBox.borderLeft = 6
	
		local label = activeListBox:createLabel({ text = "Nearby Targets:" })
		label.borderBottom = 6

		activeListPane = activeListBox:createVerticalScrollPane({})
		activeListPane.layoutWidthFraction = 1.0
		activeListPane.layoutHeightFraction = 1.0
		activeListPane.paddingAllSides = 6
		
		refreshActiveList()
	end
	
	container:getTopLevelParent():updateLayout()
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function this.onClose(container)
	mwse.saveConfig("Happy Harvesting", this.config)
end

return this