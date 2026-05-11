local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "thamner-pol",
	npcID = 2326,
	name = "Thamner Pol",
	title = "Physician",
	area = "Kharanos",
	zone = "Dun Morogh",
	coords = "47.2, 52.6",
	url = "https://www.wowhead.com/classic/npc=2326/thamner-pol",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "thamner-pol", "target"),
	targetImageSize = { 99, 93 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "thamner-pol", "model"),
	modelImageSize = { 467, 666 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "thamner-pol", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
