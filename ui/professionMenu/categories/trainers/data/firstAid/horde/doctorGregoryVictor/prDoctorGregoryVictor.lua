local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "doctor-gregory-victor",
	npcID = 12920,
	name = "Doctor Gregory Victor",
	title = "Trauma Surgeon",
	area = "Hammerfall",
	zone = "Arathi Highlands",
	coords = "73.0, 36.0",
	url = "https://www.wowhead.com/classic/npc=12920/doctor-gregory-victor",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "doctor-gregory-victor", "target"),
	targetImageSize = { 113, 94 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "doctor-gregory-victor", "model"),
	modelImageSize = { 516, 931 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "doctor-gregory-victor", "map"),
	teaches = TrainerData.FirstAidTraumaSurgeonTeaches(),
})
