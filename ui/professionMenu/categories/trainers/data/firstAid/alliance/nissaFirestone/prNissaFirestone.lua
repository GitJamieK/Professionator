local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "nissa-firestone",
	npcID = 5150,
	name = "Nissa Firestone",
	title = "First Aid Trainer",
	area = "The Great Forge",
	zone = "Ironforge",
	coords = "54.8, 58.6",
	url = "https://www.wowhead.com/classic/npc=5150/nissa-firestone",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "nissa-firestone", "target"),
	targetImageSize = { 103, 96 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "nissa-firestone", "model"),
	modelImageSize = { 348, 632 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "nissa-firestone", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
