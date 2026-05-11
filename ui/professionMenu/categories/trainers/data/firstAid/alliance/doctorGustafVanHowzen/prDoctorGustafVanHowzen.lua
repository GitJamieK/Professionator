local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "alliance", {
	id = "doctor-gustaf-vanhowzen",
	npcID = 12939,
	name = "Doctor Gustaf VanHowzen",
	title = "Trauma Surgeon",
	area = "Foothold Citadel",
	zone = "Dustwallow Marsh",
	coords = "67.0, 48.0",
	url = "https://www.wowhead.com/classic/npc=12939/doctor-gustaf-vanhowzen",
	targetImage = TrainerData.AssetPath("first-aid", "alliance", "doctor-gustaf-vanhowzen", "target"),
	targetImageSize = { 102, 95 },
	modelImage = TrainerData.AssetPath("first-aid", "alliance", "doctor-gustaf-vanhowzen", "model"),
	modelImageSize = { 464, 984 },
	mapImage = TrainerData.AssetPath("first-aid", "alliance", "doctor-gustaf-vanhowzen", "map"),
	teaches = TrainerData.FirstAidTraumaSurgeonTeaches(),
})
