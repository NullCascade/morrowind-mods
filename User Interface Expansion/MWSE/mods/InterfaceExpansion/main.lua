
local GUI_ID_MagicMenu_spell_costs
local GUI_ID_MagicMenu_spell_names
local GUI_ID_MagicMenu_spell_percents
local GUI_ID_MagicMenu_spells_list
local GUI_ID_MenuMagic
local GUI_ID_PartScrollPane_pane

local GUI_ID_UIEXP_MagicMenu_SchoolFilters

local GUI_Palette_Normal
local GUI_Palette_Disabled

local config = { showHelpText = true }

----------------------------------------------------------------------------------------------------
-- Spell List: Filtering and Searching
----------------------------------------------------------------------------------------------------

local spellsListSearchText = nil
local spellsListSchoolWhitelist = {}

local function spellMatchesFilter(spell)
	-- Filter by name.
	if (spellsListSearchText and not string.find(string.lower(spell.name), spellsListSearchText)) then
		return false
	end

	-- Filter by effects.
	for i = 1, #spell.effects do
		if (spellsListSchoolWhitelist[spell.effects[i].object.school]) then
			return true
		end
	end

	return false
end

local function searchSpellsList()
	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
	local namesList = magicMenu:findChild(GUI_ID_MagicMenu_spell_names)
	local costsList = magicMenu:findChild(GUI_ID_MagicMenu_spell_costs)
	local percentsList = magicMenu:findChild(GUI_ID_MagicMenu_spell_percents)

	-- Get a list of all children for future manipulation.
	-- These tables are created newly each time .children is accessed.
	local namesChildren = namesList.children
	local costsChildren = costsList.children
	local percentsChildren = percentsList.children

	-- 
	for index = 1, #namesChildren do
		local element = namesChildren[index]

		local filter = spellMatchesFilter(element:getPropertyObject("MagicMenu_Spell"))
		if (filter ~= element.visible) then
			element.visible = filter
			costsChildren[index].visible = filter
			percentsChildren[index].visible = filter
		end
	end
end

local function toggleSchoolBlacklistFilter(e)
	local icon = e.source
	local school = icon:getPropertyInt("UIEXP:School")

	if (spellsListSchoolWhitelist[school]) then
		icon.alpha = 0.5
		spellsListSchoolWhitelist[school] = false
	else
		icon.alpha = 1.0
		spellsListSchoolWhitelist[school] = true
	end
	icon:updateLayout()

	searchSpellsList()
end

local function setSchoolBlacklistFilter(e)
	local icon = e.source
	local school = icon:getPropertyInt("UIEXP:School")
	
	-- If this is the only element activated, show all schools.
	local shownCount = 0
	local shownSchool = nil
	for school, state in pairs(spellsListSchoolWhitelist) do
		if (state) then
			shownSchool = school
			shownCount = shownCount + 1
		end
	end
	if (shownCount == 1 and shownSchool == school) then
		for school, state in pairs(spellsListSchoolWhitelist) do
			spellsListSchoolWhitelist[school] = true
		end
		
		local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)
		local filtersBlock = magicMenu:findChild(GUI_ID_UIEXP_MagicMenu_SchoolFilters)
		local filtersChildren = filtersBlock.children
		for _, element in pairs(filtersChildren) do
			element.alpha = 1.0
			element:updateLayout()
		end

		searchSpellsList()
		return
	end

	-- If shift is pressed, toggle the element.
	if (tes3.worldController.inputController:isKeyDown(42)) then
		toggleSchoolBlacklistFilter(e)
		return 
	end

	local magicMenu = tes3ui.findMenu(GUI_ID_MenuMagic)

	local filtersBlock = magicMenu:findChild(GUI_ID_UIEXP_MagicMenu_SchoolFilters)
	local filtersChildren = filtersBlock.children
	for _, element in pairs(filtersChildren) do
		element.alpha = 0.5
		element:updateLayout()
	end

	icon.alpha = 1.0
	icon:updateLayout()

	for name, id in pairs(tes3.magicSchool) do
		spellsListSchoolWhitelist[id] = false
	end
	
	spellsListSchoolWhitelist[school] = true

	searchSpellsList()
end

local function onSchoolFilterTooltip(e)
	local icon = e.source
	local tooltip = tes3ui.createTooltipMenu()

	local tooltipBlock = tooltip:createBlock({})
	tooltipBlock.flowDirection = "top_to_bottom"
	tooltipBlock.autoHeight = true
	tooltipBlock.autoWidth = true
	
	local schoolId = icon:getPropertyInt("UIEXP:School")
	local skillId = tes3.magicSchoolSkill[schoolId]

	tooltipBlock:createLabel({ text = string.format("Filter by %s", tes3.getSkill(skillId).name) })
end

local function onMenuMagicActivated(e)
	local spellsList = e.element:findChild(GUI_ID_MagicMenu_spells_list)
	local spellsListContents = spellsList:findChild(GUI_ID_PartScrollPane_pane)

	-- Make the parent block order from top to bottom.
	local spellsListParent = spellsList.parent
	spellsListParent.flowDirection = "top_to_bottom"

	-- Create the filter block where our search bar and filter icons will live.
	local filterBlock = spellsListParent:createBlock({ id = "UIEXP:MagicMenu:FilterBlock" })
	filterBlock.flowDirection = "left_to_right"
	filterBlock.widthProportional = 1.0
	filterBlock.autoHeight = true
	filterBlock.paddingLeft = 4
	filterBlock.paddingRight = 4
	
	local searchInputBorder = filterBlock:createThinBorder({})
	searchInputBorder.autoWidth = true
	searchInputBorder.autoHeight = true
	searchInputBorder.widthProportional = 1.0
	
	-- Create the search input itself.
	local searchInput = searchInputBorder:createTextInput({ id = "UIEXP:MagicMenu:SearchInput" })
	searchInput.color = GUI_Palette_Disabled
	searchInput.text = "Search by name..."
	searchInput.borderLeft = 5
	searchInput.borderRight = 5
	searchInput.borderTop = 2
	searchInput.borderBottom = 4
	searchInput.widget.eraseOnFirstKey = true
	searchInput.widget.lengthLimit = 31

	-- Set up the 
	searchInput.consumeMouseEvents = false
	searchInput:register("keyPress", function(e)
		searchInput:forwardEvent(e)

		spellsListSearchText = searchInput.text
		if (spellsListSearchText == "") then
			spellsListSearchText = nil
		end
		searchSpellsList()
	end)
	searchInputBorder:register("mouseClick", function()
		searchInput:forwardEvent(e)

		tes3ui.acquireTextInput(searchInput)
		searchInput.color = GUI_Palette_Normal
	end)
	
	-- Create magic school filter border.
	local schoolFilterBorder = filterBlock:createThinBorder({ id = GUI_ID_UIEXP_MagicMenu_SchoolFilters })
	schoolFilterBorder.autoWidth = true
	schoolFilterBorder.autoHeight = true
	schoolFilterBorder.borderLeft = 4
	schoolFilterBorder.paddingTop = 2
	schoolFilterBorder.paddingBottom = 3
	schoolFilterBorder.paddingLeft = 2
	schoolFilterBorder.paddingRight = 3

	-- Create the individual filter icons.
	do
		local schoolFilterAlteration = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_alteration.tga" })
		schoolFilterAlteration.imageScaleX = 0.6
		schoolFilterAlteration.imageScaleY = 0.6
		schoolFilterAlteration:setPropertyInt("UIEXP:School", tes3.magicSchool.alteration)
		schoolFilterAlteration:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterAlteration:register("help", onSchoolFilterTooltip)

		local schoolFilterConjuration = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_conjuration.tga" })
		schoolFilterConjuration.borderLeft = 2
		schoolFilterConjuration.imageScaleX = 0.6
		schoolFilterConjuration.imageScaleY = 0.6
		schoolFilterConjuration:setPropertyInt("UIEXP:School", tes3.magicSchool.conjuration)
		schoolFilterConjuration:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterConjuration:register("help", onSchoolFilterTooltip)
		
		local schoolFilterDestruction = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_destruction.tga" })
		schoolFilterDestruction.borderLeft = 2
		schoolFilterDestruction.imageScaleX = 0.6
		schoolFilterDestruction.imageScaleY = 0.6
		schoolFilterDestruction:setPropertyInt("UIEXP:School", tes3.magicSchool.destruction)
		schoolFilterDestruction:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterDestruction:register("help", onSchoolFilterTooltip)
		
		local schoolFilterIllusion = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_illusion.tga" })
		schoolFilterIllusion.borderLeft = 2
		schoolFilterIllusion.imageScaleX = 0.6
		schoolFilterIllusion.imageScaleY = 0.6
		schoolFilterIllusion:setPropertyInt("UIEXP:School", tes3.magicSchool.illusion)
		schoolFilterIllusion:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterIllusion:register("help", onSchoolFilterTooltip)
		
		local schoolFilterMysticism = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_mysticism.tga" })
		schoolFilterMysticism.borderLeft = 2
		schoolFilterMysticism.imageScaleX = 0.6
		schoolFilterMysticism.imageScaleY = 0.6
		schoolFilterMysticism:setPropertyInt("UIEXP:School", tes3.magicSchool.mysticism)
		schoolFilterMysticism:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterMysticism:register("help", onSchoolFilterTooltip)
		
		local schoolFilterRestoration = schoolFilterBorder:createImage({ path = "icons/ui_exp/magic_restoration.tga" })
		schoolFilterRestoration.borderLeft = 2
		schoolFilterRestoration.imageScaleX = 0.6
		schoolFilterRestoration.imageScaleY = 0.6
		schoolFilterRestoration:setPropertyInt("UIEXP:School", tes3.magicSchool.restoration)
		schoolFilterRestoration:register("mouseClick", setSchoolBlacklistFilter)
		schoolFilterRestoration:register("help", onSchoolFilterTooltip)
	end

	-- Move the filter options to the top of the block.
	spellsListParent:reorderChildren(0, -1, 1)

	-- Default to spell searching.
	-- tes3ui.acquireTextInput(searchInput)
end
event.register("uiActivated", onMenuMagicActivated, { filter = "MenuMagic" } )


----------------------------------------------------------------------------------------------------
-- Initialization: Data collection and UI ID registration.
----------------------------------------------------------------------------------------------------

local function onInitialized(e)
	-- Pre-register extant GUI IDs.
	GUI_ID_MagicMenu_spell_costs = tes3ui.registerID("MagicMenu_spell_costs")
	GUI_ID_MagicMenu_spell_names = tes3ui.registerID("MagicMenu_spell_names")
	GUI_ID_MagicMenu_spell_percents = tes3ui.registerID("MagicMenu_spell_percents")
	GUI_ID_MagicMenu_spells_list = tes3ui.registerID("MagicMenu_spells_list")
	GUI_ID_MenuMagic = tes3ui.registerID("MenuMagic")
	GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

	-- Pre-register new GUI IDs.
	GUI_ID_UIEXP_MagicMenu_SchoolFilters = tes3ui.registerID("UIEXP_MagicMenu_SchoolFilters")

	-- Pre-register pallets.
	GUI_Palette_Normal = tes3ui.getPalette("normal_color")
	GUI_Palette_Disabled = tes3ui.getPalette("disabled_color")

	-- Fill the school filter whitelist.
	for name, id in pairs(tes3.magicSchool) do
		spellsListSchoolWhitelist[id] = true
	end
end
event.register("initialized", onInitialized)


----------------------------------------------------------------------------------------------------
-- DEBUG UTILITIES
----------------------------------------------------------------------------------------------------

local function onLoaded(e)
	if (true) then
		mwscript.addSpell({ reference = tes3.player, spell = "aralor's intervention" })
		mwscript.addSpell({ reference = tes3.player, spell = "argonian breathing" })
		mwscript.addSpell({ reference = tes3.player, spell = "baleful glower" })
		mwscript.addSpell({ reference = tes3.player, spell = "beggar's nose spell" })
		mwscript.addSpell({ reference = tes3.player, spell = "blessed touch" })
		mwscript.addSpell({ reference = tes3.player, spell = "blessed word" })
		mwscript.addSpell({ reference = tes3.player, spell = "blood_rage_unique" })
		mwscript.addSpell({ reference = tes3.player, spell = "colony_rug" })
		mwscript.addSpell({ reference = tes3.player, spell = "colovia's grace" })
		mwscript.addSpell({ reference = tes3.player, spell = "cure corprus disease" })
		mwscript.addSpell({ reference = tes3.player, spell = "cure corpus disease" })
		mwscript.addSpell({ reference = tes3.player, spell = "cure_blight_target" })
		mwscript.addSpell({ reference = tes3.player, spell = "emperor's blessing" })
		mwscript.addSpell({ reference = tes3.player, spell = "eye of night" })
		mwscript.addSpell({ reference = tes3.player, spell = "eye of talos" })
		mwscript.addSpell({ reference = tes3.player, spell = "father ahaz" })
		mwscript.addSpell({ reference = tes3.player, spell = "felms' glory" })
		mwscript.addSpell({ reference = tes3.player, spell = "fireball_bar_uni" })
		mwscript.addSpell({ reference = tes3.player, spell = "gaenor_spell" })
		mwscript.addSpell({ reference = tes3.player, spell = "ghost_snake" })
		mwscript.addSpell({ reference = tes3.player, spell = "glenmoril_ring" })
		mwscript.addSpell({ reference = tes3.player, spell = "hand of dagoth" })
		mwscript.addSpell({ reference = tes3.player, spell = "hand of the hart-king" })
		mwscript.addSpell({ reference = tes3.player, spell = "HealingTouch_SP_uniq" })
		mwscript.addSpell({ reference = tes3.player, spell = "heavy_eyes_unique" })
		mwscript.addSpell({ reference = tes3.player, spell = "hroldar_death" })
		mwscript.addSpell({ reference = tes3.player, spell = "hrothmund blessing" })
		mwscript.addSpell({ reference = tes3.player, spell = "icarian_flight" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial acrobatics skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial alchemy skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial alteration skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial armorer skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial athletics skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial axe skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial block skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial blunt weapon skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial conjuration skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial destruction skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial enchant skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial hand to hand skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial heavy armor skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial illusion skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial light armor skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial long blade skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial marksman skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial medium armor skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial mercantile skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial mysticism skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial restoration skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial security skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial short blade skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial sneak skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial spear skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial speechcraft skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "imperial unarmored skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "kwama_poison" })
		mwscript.addSpell({ reference = tes3.player, spell = "lady's grace shrine" })
		mwscript.addSpell({ reference = tes3.player, spell = "meris' warding" })
		mwscript.addSpell({ reference = tes3.player, spell = "meris's warding" })
		mwscript.addSpell({ reference = tes3.player, spell = "nchuleftingth_trap_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "nibenay's wit" })
		mwscript.addSpell({ reference = tes3.player, spell = "olms' benediction" })
		mwscript.addSpell({ reference = tes3.player, spell = "proj_trap_spell" })
		mwscript.addSpell({ reference = tes3.player, spell = "relvel_damage" })
		mwscript.addSpell({ reference = tes3.player, spell = "reman's girdle" })
		mwscript.addSpell({ reference = tes3.player, spell = "rilm's gift" })
		mwscript.addSpell({ reference = tes3.player, spell = "roris' bloom" })
		mwscript.addSpell({ reference = tes3.player, spell = "roris's bloom" })
		mwscript.addSpell({ reference = tes3.player, spell = "shield of st. delyn" })
		mwscript.addSpell({ reference = tes3.player, spell = "shockblast" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine acrobatics skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine alchemy skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine alteration skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine armorer skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine athletics skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine axe skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine block skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine blunt weapon skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine conjuration skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine destruction skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine enchant skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine hand to hand skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine heavy armor skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine illusion skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine light armor skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine long blade skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine marksman skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine medium armor skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine mercantile skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine mysticism skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine restoration skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine security skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine short blade skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine sneak skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine spear skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine speechcraft skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine unarmored skill" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_aldsotha_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_balur_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_balur2_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_dagonfel_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_gnisis_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_koalcave_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_kummu_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_maargan_npc_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_maargan_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_palace_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "shrine_stopmoon_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "skillmephala_sp" })
		mwscript.addSpell({ reference = tes3.player, spell = "soul of sotha sil" })
		mwscript.addSpell({ reference = tes3.player, spell = "sp_ccd" })
		mwscript.addSpell({ reference = tes3.player, spell = "sp_touchprotect" })
		mwscript.addSpell({ reference = tes3.player, spell = "spirit of nerevar" })
		mwscript.addSpell({ reference = tes3.player, spell = "star-curse" })
		mwscript.addSpell({ reference = tes3.player, spell = "stone_erlendr" })
		mwscript.addSpell({ reference = tes3.player, spell = "stone_hunroor" })
		mwscript.addSpell({ reference = tes3.player, spell = "stone_nikulas" })
		mwscript.addSpell({ reference = tes3.player, spell = "stone_ulfgar" })
		mwscript.addSpell({ reference = tes3.player, spell = "summon_centurion_unique" })
		mwscript.addSpell({ reference = tes3.player, spell = "the dove's promise" })
		mwscript.addSpell({ reference = tes3.player, spell = "the eight gifts" })
		mwscript.addSpell({ reference = tes3.player, spell = "the eight wonders" })
		mwscript.addSpell({ reference = tes3.player, spell = "the moth-wing mirror" })
		mwscript.addSpell({ reference = tes3.player, spell = "the red diamond" })
		mwscript.addSpell({ reference = tes3.player, spell = "the rock of llothis" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_fire_killer" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_fire00" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_frost_killer" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_frost00" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_health00" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_paralyze00" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_poison_killer" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_poison00" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_shock_killer" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_shock00" })
		mwscript.addSpell({ reference = tes3.player, spell = "trap_silence00" })
		mwscript.addSpell({ reference = tes3.player, spell = "ulfgar_ghost_ring" })
		mwscript.addSpell({ reference = tes3.player, spell = "vampire levitate" })
		mwscript.addSpell({ reference = tes3.player, spell = "vivec's fury" })
		mwscript.addSpell({ reference = tes3.player, spell = "vivec's mystery" })
		mwscript.addSpell({ reference = tes3.player, spell = "werewolf_ritual_ring" })
		mwscript.addSpell({ reference = tes3.player, spell = "wulfharth's cups" })
		mwscript.addSpell({ reference = tes3.player, spell = "ysmir's cough" })
	end
end
event.register("loaded", onLoaded)
