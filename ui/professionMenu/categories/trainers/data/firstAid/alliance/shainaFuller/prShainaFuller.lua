local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "shaina-fuller",
	npcID = 2327,
	name = "Shaina Fuller",
	title = "First Aid Trainer",
	area = "Cathedral of Light",
	zone = "Stormwind City",
	coords = "42.8, 26.6",
	url = "https://www.wowhead.com/classic/npc=2327/shaina-fuller",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "shaina-fuller", "target"),
	targetImageSize = { 103, 92 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "shaina-fuller", "model"),
	modelImageSize = { 504, 914 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "shaina-fuller", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
