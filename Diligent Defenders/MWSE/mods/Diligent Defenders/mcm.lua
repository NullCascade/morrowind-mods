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
		this.config.ignoreList[id] = nil
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

	local sortedBlacklistIds = {}
	for id, _ in pairs(this.config.ignoreList) do
		table.insert(sortedBlacklistIds, id)
	end
	table.sort(sortedBlacklistIds, caseInsensitiveSorter)
	
	for _, id in ipairs(sortedBlacklistIds) do
		createBlackListRow(blackListPane, id)
	end
end

local activeListPane
local activeListActualPane

local function createActiveListRow(container, follower)
	local row = container:createBlock({})
	row.layoutWidthFraction = 1.0
	row.autoHeight = true
	activeListActualPane = row.parent

	local followerBaseId = follower.id
	if (follower.isInstance) then
		followerBaseId = follower.baseObject.id
	end

	local label = row:createLabel({ text = followerBaseId })

	if (not this.config.ignoreList[followerBaseId]) then
		local removeBtn = row:createButton({ text = "Blacklist" })
		removeBtn.layoutOriginFractionX = 1.0
		removeBtn:register("mouseClick", function(e)
			this.config.ignoreList[followerBaseId] = true
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

	local macp = tes3.mobilePlayer
	if (macp) then
		for actor in tes3.iterate(macp.friendlyActors) do
			-- If the companion doesn't currently have a target, isn't the player, and isn't in a blacklist, start combat.
			if (actor ~= macp) then
				createActiveListRow(activeListPane, actor.reference.object)
			end
		end
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
		descriptionLabel = container:createLabel({ text = "Diligent Defenders makes friendly actors join you at the start of combat, instead of waiting for their AI to catch on that combat has begun. Some friendly actors should remain neutral, however. Using the information below, you can view the current blacklist, as well as the current actors that are considered friendly. To prevent an actor ID from joining you in combat, click the blacklist button. You may also remove actors from the blacklist." })
	else
		descriptionLabel = container:createLabel({ text = "Diligent Defenders makes friendly actors join you at the start of combat, instead of waiting for their AI to catch on that combat has begun. Using the information below, you can view and modify the current blacklist. To view and blacklist actors, load a save game." })
	end
	descriptionLabel.layoutWidthFraction = 1.0
	descriptionLabel.wrapText = true
	descriptionLabel.layoutHeightFraction = -1
	descriptionLabel.borderBottom = 12

	local splitPane = container:createBlock({})
	splitPane.flowDirection = "left_to_right"
	splitPane.layoutWidthFraction = 1.0
	splitPane.layoutHeightFraction = 1.0

	do
		local blackListBox = splitPane:createBlock({})
		blackListBox.flowDirection = "top_to_bottom"
		blackListBox.layoutWidthFraction = 1.0
		blackListBox.layoutHeightFraction = 1.0
	
		local label = blackListBox:createLabel({ text = "Ignore List:" })
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
	
		local label = activeListBox:createLabel({ text = "Friendly Actors:" })
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
	mwse.saveConfig("Diligent Defenders", this.config)
end

return this