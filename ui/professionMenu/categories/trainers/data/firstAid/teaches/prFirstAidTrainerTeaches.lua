local _, ns = ...

local TrainerData = ns.ProfessionTrainerData

function TrainerData.FirstAidTrainerTeaches()
	return {
		{
			name = "First Aid",
			rank = "Apprentice",
			type = "rank",
			spellID = 3273,
			source = "Trainer",
			requiredSkill = 0,
			skillCap = 75,
			description = "Initial First Aid training and early bandage access.",
			wowheadURL = "https://www.wowhead.com/classic/spell=3273/first-aid",
		},
		{
			name = "First Aid",
			rank = "Journeyman",
			type = "rank",
			spellID = 3274,
			source = "Trainer",
			requiredSkill = 50,
			skillCap = 150,
			description = "Extends First Aid training beyond Apprentice.",
			wowheadURL = "https://www.wowhead.com/classic/spell=3274/first-aid",
		},
		{
			name = "Anti-Venom",
			type = "craft",
			spellID = 7934,
			source = "Trainer",
			requiredSkill = 80,
			castTime = "3 sec",
			reagents = {
				{ itemID = 1475, name = "Small Venom Sac", quantity = 1 },
			},
			creates = {
				itemID = 6452,
				name = "Anti-Venom",
				quantity = 3,
			},
			effect = "Cures poisons up to level 25. 1 min cooldown.",
			skillColors = { 80, 80, 115, 150 },
			wowheadURL = "https://www.wowhead.com/classic/spell=7934/anti-venom",
		},
		{
			name = "Wool Bandage",
			type = "craft",
			spellID = 3277,
			source = "Trainer",
			requiredSkill = 80,
			itemRequiredSkill = 50,
			castTime = "3 sec",
			reagents = {
				{ itemID = 2592, name = "Wool Cloth", quantity = 1 },
			},
			creates = {
				itemID = 3530,
				name = "Wool Bandage",
				quantity = 1,
			},
			effect = "Heals 161 damage over 7 sec.",
			skillColors = { 80, 80, 115, 150 },
			wowheadURL = "https://www.wowhead.com/classic/spell=3277/wool-bandage",
		},
		{
			name = "Heavy Wool Bandage",
			type = "craft",
			spellID = 3278,
			source = "Trainer",
			requiredSkill = 115,
			itemRequiredSkill = 75,
			castTime = "3 sec",
			reagents = {
				{ itemID = 2592, name = "Wool Cloth", quantity = 2 },
			},
			creates = {
				itemID = 3531,
				name = "Heavy Wool Bandage",
				quantity = 1,
			},
			effect = "Heals 301 damage over 7 sec.",
			skillColors = { 115, 115, 150, 185 },
			wowheadURL = "https://www.wowhead.com/classic/spell=3278/heavy-wool-bandage",
		},
		{
			name = "Silk Bandage",
			type = "craft",
			spellID = 7928,
			source = "Trainer",
			requiredSkill = 150,
			itemRequiredSkill = 100,
			castTime = "3 sec",
			reagents = {
				{ itemID = 4306, name = "Silk Cloth", quantity = 1 },
			},
			creates = {
				itemID = 6450,
				name = "Silk Bandage",
				quantity = 1,
			},
			effect = "Heals 400 damage over 8 sec.",
			skillColors = { 150, 150, 180, 210 },
			wowheadURL = "https://www.wowhead.com/classic/spell=7928/silk-bandage",
		},
	}
end
