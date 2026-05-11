local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "rawrk",
	npcID = 5943,
	name = "Rawrk",
	title = "First Aid Trainer",
	area = "Razor Hill",
	zone = "Durotar",
	coords = "54.0, 42.0",
	url = "https://www.wowhead.com/classic/npc=5943/rawrk",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "rawrk", "target"),
	targetImageSize = { 112, 95 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "rawrk", "model"),
	modelImageSize = { 512, 741 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "rawrk", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
