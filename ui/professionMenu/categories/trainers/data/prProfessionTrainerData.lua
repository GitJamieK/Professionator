local _, ns = ...

local TrainerData = ns.ProfessionTrainerData or {}
ns.ProfessionTrainerData = TrainerData

local SCREENSHOT_ROOT = "Interface\\AddOns\\Professionator\\img\\screenshots"

function TrainerData.AssetPath(professionID, factionID, trainerID, imageType)
	return SCREENSHOT_ROOT .. "\\trainers\\" .. professionID .. "\\" .. factionID .. "\\" .. trainerID .. "\\" .. imageType .. ".png"
end

function TrainerData.RegisterTrainer(professionID, factionID, trainer)
	if not ns.ProfessionData then
		return
	end

	local trainerData = ns.ProfessionData.trainerData or {}
	ns.ProfessionData.trainerData = trainerData

	local professionData = trainerData[professionID] or {}
	trainerData[professionID] = professionData

	local factionData = professionData[factionID] or {}
	professionData[factionID] = factionData

	table.insert(factionData, trainer)
end
