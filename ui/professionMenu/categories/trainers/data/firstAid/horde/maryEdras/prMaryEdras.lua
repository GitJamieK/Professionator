local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "mary-edras",
	npcID = 4591,
	name = "Mary Edras",
	title = "First Aid Trainer",
	area = "Rogues' Quarter",
	zone = "Undercity",
	coords = "73.6, 55.6",
	url = "https://www.wowhead.com/classic/npc=4591/mary-edras",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "mary-edras", "target"),
	targetImageSize = { 113, 94 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "mary-edras", "model"),
	modelImageSize = { 333, 646 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "mary-edras", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
