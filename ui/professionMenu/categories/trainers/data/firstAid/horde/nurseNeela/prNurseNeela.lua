local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "nurse-neela",
	npcID = 5759,
	name = "Nurse Neela",
	title = "First Aid Trainer",
	area = "Brill",
	zone = "Tirisfal Glades",
	coords = "61.8, 52.8",
	url = "https://www.wowhead.com/classic/npc=5759/nurse-neela",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "nurse-neela", "target"),
	targetImageSize = { 112, 94 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "nurse-neela", "model"),
	modelImageSize = { 332, 723 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "nurse-neela", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
