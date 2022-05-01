return {
	["core.credits"] = "by NullCascade",
	["core.modName"] = "Less Lame Leveled Spawns",
	["core.versionString"] = "v1.0.0",
	["mcm.about"] = "This mod prevents leveled spawns from appearing when it wouldn't make sense. This is primarily to fix an issue where loading a save in a dungeon would cause the spawns to reappear if corpses were disposed of. It accomplishes this by two methods:\n\nFirst, it prevents leveled creature spawns from resolving when the game is loading.\n\nSecond (disabled by default), it prevents spawns from resolving until after a number of hours have passed since the last spawn. The hours it takes is determined by the fCorpseRespawnDelay GMST.",
	["mcm.blockSpawnsWhenLoading.description"] = "Prevents leveled creature spawns from resolving when the game is loading. This is lightweight, leads to no save bloat, and fixes the issue of spawns appearing in front of the player when fresh-loading a game in a dungeon.\n\nDefault: Enabled",
	["mcm.blockSpawnsWhenLoading.label"] = "Prevent spawns when loading?",
	["mcm.blockSpawnsWithCooldown.description"] = "Prevents spawns from resolving until after a number of hours have passed since the last spawn. The hours it takes is determined by the fCorpseRespawnDelay GMST. This stores more data in the save, but ultimately saves more space if the creatures are killed by allowing the player to dispose of corpses safely, knowing that they won't reappear for (by default) 72 hours.\n\nDefault: Disabled",
	["mcm.blockSpawnsWithCooldown.label"] = "Prevent spawns with a cooldown?",
}
