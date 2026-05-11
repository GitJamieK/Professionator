local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "dannelor",
	npcID = 4211,
	name = "Dannelor",
	title = "First Aid Trainer",
	area = "Craftsmen's Terrace",
	zone = "Darnassus",
	coords = "51.6, 12.6",
	url = "https://www.wowhead.com/classic/npc=4211/dannelor",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "dannelor", "target"),
	targetImageSize = { 102, 95 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "dannelor", "model"),
	modelImageSize = { 395, 958 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "dannelor", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
