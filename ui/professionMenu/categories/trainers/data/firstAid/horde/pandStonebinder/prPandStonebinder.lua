local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

TrainerData.RegisterTrainer("first-aid", "horde", {
	id = "pand-stonebinder",
	npcID = 2798,
	name = "Pand Stonebinder",
	title = "First Aid Trainer",
	area = "Spirit Rise",
	zone = "Thunder Bluff",
	coords = "29.6, 21.4",
	url = "https://www.wowhead.com/classic/npc=2798/pand-stonebinder",
	targetImage = TrainerData.AssetPath("first-aid", "horde", "pand-stonebinder", "target"),
	targetImageSize = { 112, 96 },
	modelImage = TrainerData.AssetPath("first-aid", "horde", "pand-stonebinder", "model"),
	modelImageSize = { 740, 967 },
	mapImage = TrainerData.AssetPath("first-aid", "horde", "pand-stonebinder", "map"),
	teaches = TrainerData.FirstAidTrainerTeaches(),
})
