local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "fremal-doohickey",
	npcID = 3181,
	name = "Fremal Doohickey",
	title = "First Aid Trainer",
	area = "Menethil Harbor",
	zone = "Wetlands",
	coords = "10.8, 61.2",
	url = "https://www.wowhead.com/classic/npc=3181/fremal-doohickey",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "fremal-doohickey", "target"),
	targetImageSize = { 103, 95 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "fremal-doohickey", "model"),
	modelImageSize = { 524, 770 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "fremal-doohickey", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
