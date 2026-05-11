local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "michelle-belle",
	npcID = 2329,
	name = "Michelle Belle",
	title = "Physician",
	area = "Goldshire",
	zone = "Elwynn Forest",
	coords = "43.4, 65.6",
	url = "https://www.wowhead.com/classic/npc=2329/michelle-belle",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "michelle-belle", "target"),
	targetImageSize = { 102, 94 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "michelle-belle", "model"),
	modelImageSize = { 374, 959 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "michelle-belle", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
