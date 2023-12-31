local interop = require("Profiler.interop")

local GUIID_ProfilerHelpMenu
local GUIID_ProfilerResultsMenu
event.register("initialized", function()
	GUIID_ProfilerHelpMenu = tes3ui.registerID("ProfilerHelpMenu")
	GUIID_ProfilerResultsMenu = tes3ui.registerID("ProfilerMenu")
end)

local function getNthLine(fileName, n)
	local f = assert(io.open(fileName, "r"))
	local i = 1
	for line in f:lines() do
		if i == n then
			f:close()
			return line
		end
		i = i + 1
	end
	f:close()
	error("No hit on line " .. n)
end

local function startProfiler()
	if (tes3ui.findHelpLayerMenu(GUIID_ProfilerHelpMenu)) then
		return
	end

	local resultsMenu = tes3ui.findMenu(GUIID_ProfilerResultsMenu)
	if (resultsMenu) then
		resultsMenu:destroy()
	end

	local helpMenu = tes3ui.createHelpLayerMenu({ id = GUIID_ProfilerHelpMenu, fixedFrame = true })
	helpMenu:destroyChildren()
	helpMenu.disabled = true
    helpMenu.absolutePosAlignX = 0.02
    helpMenu.absolutePosAlignY = 0.04
    helpMenu.color = {0, 0, 0}
    helpMenu.alpha = 0.8
    helpMenu.autoWidth = true
    helpMenu.autoHeight = true
    helpMenu.paddingAllSides = 12
	helpMenu:createLabel({ text = "Profiler active..." })

	helpMenu:updateLayout()

	interop.start()
end

local function stopProfiler()
	-- Remove the profiler active help menu.
	local helpMenu = tes3ui.findHelpLayerMenu(GUIID_ProfilerHelpMenu)
	if (helpMenu) then
		helpMenu:destroy()
	end

	-- Show the results menu.
	local menu = tes3ui.createMenu({ id = GUIID_ProfilerResultsMenu, dragFrame = true })
    menu.text = "Profiler Results"
	-- menu.flowDirection = "top_to_bottom"
	menu.width = 800
	menu.height = 600
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
	menu:loadMenuPosition()

	do
		local header = menu:createBlock()
		header.widthProportional = 1.0
		header.autoHeight = true
		header.borderLeft = 5
		header.borderRight = 25
		local columnLine = header:createLabel({ text = "Line" })
		columnLine.absolutePosAlignX = 0
		local columnHits = header:createLabel({ text = "Hits" })
		columnHits.absolutePosAlignX = 1.0
	end

	-- Get the total number of hits.
	local results = interop.getResults()
	local resultsTotalCount = 0
	for _, data in pairs(results) do
		resultsTotalCount = resultsTotalCount + data.count
	end

	-- Write out results.
	local resultsBox = menu:createVerticalScrollPane()
	for _, line in ipairs(interop.getSortedLinesByCount()) do
		local data = results[line]

		local columnsBlock = resultsBox:createBlock()
		columnsBlock.borderAllSides = 2
		columnsBlock.borderBottom = 2
		columnsBlock.autoHeight = true
		columnsBlock.widthProportional = 1.0

		local columnLine = columnsBlock:createTextSelect({ text = interop.formatLine(line) })
		columnLine.absolutePosAlignX = 0
		columnLine:register("mouseClick", function ()
			os.execute(string.format([[code -g "%s"]], line))
		end)
		columnLine:register("help", function(e)
			local tooltip = tes3ui.createTooltipMenu()

			local source = data.source
			if (source == nil) then
				local split = string.split(line, ":")
				local file = split[1]
				local lineNo = tonumber(split[2])
				source = getNthLine(file, lineNo)
				data.source = source
			end

			tooltip:createLabel({ text = source })
		end)

		local columnHits = columnsBlock:createLabel({ text = string.format("%.0f%%", (data.count / resultsTotalCount) * 100) })
		columnHits.absolutePosAlignX = 1.0
		columnHits.borderRight = 2
	end

	-- Make close button.
	local footer = menu:createBlock()
	footer.widthProportional = 1.0
	footer.autoHeight = true
	footer.borderTop = 5
	local closeButton = footer:createButton({ text = "Close" })
	closeButton.autoWidth = true
	closeButton.autoHeight = true
    closeButton.absolutePosAlignX = 1.0
	closeButton:register("mouseClick", function()
		menu:destroy()
	end)

	menu:updateLayout()
	menu:register("destroy", function()
		interop.reset()
	end)

	tes3ui.enterMenuMode(menu)

	interop.stop()
end

local profilerActive = false

local function updateProfilerState(e)
	if (profilerActive) then
		-- Stop and show results.
		stopProfiler()
	else
		startProfiler()
	end
	profilerActive = not profilerActive
end
event.register("keyDown", updateProfilerState, { filter = tes3.scanCode.F11 } )
