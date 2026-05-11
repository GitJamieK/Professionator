local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

function TrainerData.FirstAidTraumaSurgeonTeaches()
	return {
		{
			name = "First Aid",
			rank = "Artisan",
			type = "rank",
			spellID = 10846,
			source = "Quest",
			requiredSkill = 225,
			characterLevel = 35,
			skillCap = 300,
			description = "Complete Triage to raise the First Aid cap to 300.",
			wowheadURL = "https://www.wowhead.com/classic/spell=10846/first-aid",
		},
		{
			name = "Heavy Mageweave Bandage",
			type = "craft",
			spellID = 10841,
			source = "Trainer",
			requiredSkill = 240,
			itemRequiredSkill = 175,
			castTime = "3 sec",
			reagents = {
				{ itemID = 4338, name = "Mageweave Cloth", quantity = 2 },
			},
			creates = {
				itemID = 8545,
				name = "Heavy Mageweave Bandage",
				quantity = 1,
			},
			effect = "Heals 1104 damage over 8 sec.",
			skillColors = { 240, 240, 270, 300 },
			wowheadURL = "https://www.wowhead.com/classic/spell=10841/heavy-mageweave-bandage",
		},
		{
			name = "Runecloth Bandage",
			type = "craft",
			spellID = 18629,
			source = "Trainer",
			requiredSkill = 260,
			itemRequiredSkill = 200,
			castTime = "3 sec",
			reagents = {
				{ itemID = 14047, name = "Runecloth", quantity = 1 },
			},
			creates = {
				itemID = 14529,
				name = "Runecloth Bandage",
				quantity = 1,
			},
			effect = "Heals 1360 damage over 8 sec.",
			skillColors = { 260, 260, 290, 320 },
			wowheadURL = "https://www.wowhead.com/classic/spell=18629/runecloth-bandage",
		},
		{
			name = "Heavy Runecloth Bandage",
			type = "craft",
			spellID = 18630,
			source = "Trainer",
			requiredSkill = 290,
			itemRequiredSkill = 225,
			castTime = "3 sec",
			reagents = {
				{ itemID = 14047, name = "Runecloth", quantity = 2 },
			},
			creates = {
				itemID = 14530,
				name = "Heavy Runecloth Bandage",
				quantity = 1,
			},
			effect = "Heals 2000 damage over 8 sec.",
			skillColors = { 290, 290, 320, 350 },
			wowheadURL = "https://www.wowhead.com/classic/spell=18630/heavy-runecloth-bandage",
		},
	}
end
