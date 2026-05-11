local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "byancie",
	npcID = 6094,
	name = "Byancie",
	title = "First Aid Trainer",
	area = "Dolanaar",
	zone = "Teldrassil",
	coords = "55.2, 56.8",
	url = "https://www.wowhead.com/classic/npc=6094/byancie",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "byancie", "target"),
	targetImageSize = { 102, 94 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "byancie", "model"),
	modelImageSize = { 353, 994 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "byancie", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
