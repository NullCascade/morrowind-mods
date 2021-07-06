
--[[
	Mod Initialization: Diligent Defenders
	Author: NullCascade

	This module makes it so that when the player or the player's companions are attacked, any companions
	will launch into action in defense.

]]--

-- Ensure we have the features we need.
if (mwse.buildDate == nil or mwse.buildDate < 20180725) then
	mwse.log("[Diligent Defenders] Build date of %s does not meet minimum build date of 20180725.", mwse.buildDate)
	return
end

local lfs = require("lfs")

-- Ensure we don't have an old version installed.
if (lfs.attributes("Data Files/MWSE/lua/nc/defenders/mod_init.lua")) then
	if (lfs.rmdir("Data Files/MWSE/lua/nc/defenders/", true)) then
		mwse.log("[Diligent Defenders] Old install found and deleted.")

		-- Additional, probably not necessarily cleanup. It will only delete these if they are empty.
		lfs.rmdir("Data Files/MWSE/lua/nc")
		lfs.rmdir("Data Files/MWSE/lua")
	else
		mwse.log("[Diligent Defenders] Old install found but could not be deleted. Please remove the folder 'Data Files/MWSE/lua/nc/consume' and restart Morrowind.")
		return
	end
end

local config = mwse.loadConfig("Diligent Defenders", {
	ignoreList = {
		["ab01amago"] = true,
		["ab01amemasu"] = true,
		["ab01angel"] = true,
		["ab01angelshark"] = true,
		["ab01asiaarowana"] = true,
		["ab01ayu"] = true,
		["ab01barramundi"] = true,
		["ab01bat01"] = true,
		["ab01bat02"] = true,
		["ab01bee01"] = true,
		["ab01benizake"] = true,
		["ab01bird01"] = true,
		["ab01bird02"] = true,
		["ab01bird03"] = true,
		["ab01bird04"] = true,
		["ab01bird05"] = true,
		["ab01bird06"] = true,
		["ab01bird07"] = true,
		["ab01bird10"] = true,
		["ab01bird11"] = true,
		["ab01bird12"] = true,
		["ab01bird13"] = true,
		["ab01bird14"] = true,
		["ab01bird15"] = true,
		["ab01blackbass"] = true,
		["ab01bluegill"] = true,
		["ab01bluemerlin"] = true,
		["ab01bluetang"] = true,
		["ab01bluewhale"] = true,
		["ab01bocaccio"] = true,
		["ab01bora"] = true,
		["ab01browntrout"] = true,
		["ab01butterfly01"] = true,
		["ab01butterfly02"] = true,
		["ab01butterfly03"] = true,
		["ab01butterfly04"] = true,
		["ab01cecaelia"] = true,
		["ab01chinook"] = true,
		["ab01clownfish"] = true,
		["ab01colossoma"] = true,
		["ab01crab01"] = true,
		["ab01crab02"] = true,
		["ab01crab03"] = true,
		["ab01crabking"] = true,
		["ab01crabprince"] = true,
		["ab01demekin"] = true,
		["ab01dolphin"] = true,
		["ab01dolphinsmall"] = true,
		["ab01dreughancient"] = true,
		["ab01dreughelder"] = true,
		["ab01duck01"] = true,
		["ab01duck01b"] = true,
		["ab01duck06"] = true,
		["ab01duck06b"] = true,
		["ab01duck11"] = true,
		["ab01duck11b"] = true,
		["ab01duck13"] = true,
		["ab01duck13b"] = true,
		["ab01duck17"] = true,
		["ab01duck17b"] = true,
		["ab01duck23"] = true,
		["ab01duck23b"] = true,
		["ab01duckling02"] = true,
		["ab01duckling02b"] = true,
		["ab01duckling04"] = true,
		["ab01duckling04b"] = true,
		["ab01duckling06"] = true,
		["ab01duckling06b"] = true,
		["ab01duckling12"] = true,
		["ab01duckling12b"] = true,
		["ab01firefly01"] = true,
		["ab01giantshark"] = true,
		["ab01gondolier"] = true,
		["ab01gondolier2"] = true,
		["ab01goose01"] = true,
		["ab01goose01b"] = true,
		["ab01guppybluegrass"] = true,
		["ab01hariyo"] = true,
		["ab01haze"] = true,
		["ab01hermitcrab"] = true,
		["ab01humpback"] = true,
		["ab01jellyfish"] = true,
		["ab01jellyfishbig"] = true,
		["ab01kamuruti"] = true,
		["ab01katuo"] = true,
		["ab01kazika"] = true,
		["ab01kelpbass"] = true,
		["ab01kihada"] = true,
		["ab01killerwhale"] = true,
		["ab01killerwhalesmall"] = true,
		["ab01koi"] = true,
		["ab01koi2"] = true,
		["ab01kumanomi"] = true,
		["ab01kuromaguro"] = true,
		["ab01leopardshark"] = true,
		["ab01manatee"] = true,
		["ab01manbou"] = true,
		["ab01mangrovejack"] = true,
		["ab01mantaray"] = true,
		["ab01mantaray2"] = true,
		["ab01medaka"] = true,
		["ab01mezirozame"] = true,
		["ab01namazu"] = true,
		["ab01napoleon"] = true,
		["ab01neontetra"] = true,
		["ab01nizimasu"] = true,
		["ab01northernpike"] = true,
		["ab01octopus"] = true,
		["ab01octopussmall"] = true,
		["ab01oikawa"] = true,
		["ab01osyoro"] = true,
		["ab01oyanirami"] = true,
		["ab01pacificcod"] = true,
		["ab01penguin01"] = true,
		["ab01penguin01small"] = true,
		["ab01pinksalmon"] = true,
		["ab01rantyu"] = true,
		["ab01redbetta"] = true,
		["ab01reddevil"] = true,
		["ab01redhead"] = true,
		["ab01redparrot"] = true,
		["ab01sdozyou"] = true,
		["ab01seahorse"] = true,
		["ab01seal"] = true,
		["ab01sealsmall"] = true,
		["ab01seaturtle"] = true,
		["ab01seaturtlesmall"] = true,
		["ab01severus"] = true,
		["ab01shark"] = true,
		["ab01sharksucker"] = true,
		["ab01sheephead"] = true,
		["ab01shovelnose"] = true,
		["ab01siamesetiger"] = true,
		["ab01slaughterfishelder"] = true,
		["ab01snail01"] = true,
		["ab01snail02"] = true,
		["ab01snail03"] = true,
		["ab01snail04"] = true,
		["ab01snail05"] = true,
		["ab01spermwhale"] = true,
		["ab01steelhead"] = true,
		["ab01suzuki"] = true,
		["ab01tanago"] = true,
		["ab01trout1"] = true,
		["ab01trout2"] = true,
		["ab01trout3"] = true,
		["ab01trout4"] = true,
		["ab01trout5"] = true,
		["ab01turquoisediscus"] = true,
		["ab01waternetch"] = true,
		["ab01yamame"] = true,
		["ab01zatou"] = true,
		["bm_horker_swim_unique"] = true,
		["chargen boat guard 2"] = true,
		["guar_white_unique"] = true,
		["hlaalu guard_outside"] = true,
		["hlaalu guard"] = true,
		["imperial guard_ebonhear"] = true,
		["imperial guard"] = true,
		["ordinator stationary"] = true,
		["ordinator wander"] = true,
		["ordinator_high fane"] = true,
		["ordinator_mournhold"] = true,
		["redoran guard female"] = true,
		["redoran guard male"] = true,
		["telvanni guard"] = true,
		["telvanni sharpshooter"] = true,
		["ughash gro-batul"] = true,
		["yashnarz gro-ufthamph"] = true,
	}
})

-- Convert legacy blacklist into ignore list's new format.
if (config.blacklist) then
	for _, id in ipairs(config.blacklist) do
		config.ignoreList[id:lower()] = true
	end
	config.blacklist = nil

	mwse.saveConfig("Diligent Defenders", config)
end

-- Package to send to the mod config.
local modConfig = require("Diligent Defenders.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Diligent Defenders", modConfig)
end
event.register("modConfigReady", registerModConfig)

-- Check to see if the companion is in a blacklist.
local function inBlackList(actor)
	local reference = actor.reference

	-- Is it in our blacklist?
	if (config.ignoreList[reference.baseObject.id:lower()]) then
		return true
	end

	-- We didn't find it in the blacklist table above.
	return false
end

-- Checks to see if the mobile actor is one of the player's companions.
local function isPlayerCompanion(target)
	local playerMobile = tes3.getMobilePlayer()
	for actor in tes3.iterate(playerMobile.friendlyActors) do
		if (actor == target) then
			return true
		end
	end
	return false
end

-- Whenever combat starts, see if it is with the player or one of his companions. If it is, launch the companions into action.
local function onCombatStart(e)
	-- We only care if a companion (which includes the player) is entering combat.
	if (not isPlayerCompanion(e.target)) then
		return
	end

	-- Loop through player companions.
	local macp = tes3.mobilePlayer
	for actor in tes3.iterate(macp.friendlyActors) do
		-- If the companion doesn't currently have a target, isn't the player, and isn't in a blacklist, start combat.
		if (actor.actionData.target == nil and actor ~= macp and not inBlackList(actor)) then
			mwscript.startCombat({ reference = actor.reference, target = e.actor.reference })
		end
	end
end
event.register("combatStarted", onCombatStart)
