local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "vira-younghoof",
	npcID = 5939,
	name = "Vira Younghoof",
	title = "First Aid Trainer",
	area = "Bloodhoof Village",
	zone = "Mulgore",
	coords = "46.8, 60.8",
	url = "https://www.wowhead.com/classic/npc=5939/vira-younghoof",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "vira-younghoof", "target"),
	targetImageSize = { 113, 96 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "vira-younghoof", "model"),
	modelImageSize = { 544, 959 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "vira-younghoof", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
