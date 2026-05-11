local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "arnok",
	npcID = 3373,
	name = "Arnok",
	title = "First Aid Trainer",
	area = "Valley of Spirits",
	zone = "Orgrimmar",
	coords = "34.0, 84.4",
	url = "https://www.wowhead.com/classic/npc=3373/arnok",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "arnok", "target"),
	targetImageSize = { 113, 96 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "arnok", "model"),
	modelImageSize = { 793, 713 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "arnok", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
