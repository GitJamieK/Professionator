local _, ns = ...

local Shared = ns.ProfessionMenuShared

local Trainers = ns.ProfessionMenuTrainers or {}
ns.ProfessionMenuTrainers = Trainers

local Constants = {
	FACTION_BUTTON_WIDTH = 112,
	FACTION_BUTTON_HEIGHT = 32,
	FACTION_BUTTON_GAP = 10,
	TRAINER_ROW_WIDTH = 470,
	TRAINER_ROW_HEIGHT = 78,
	TRAINER_ROW_GAP = 8,
	TRAINER_IMAGE_WIDTH = 72,
	TRAINER_IMAGE_HEIGHT = 66,
	TRAINER_LIST_HEIGHT = 300,
	TRAINER_DETAIL_PANEL_WIDTH = 492,
	TRAINER_DETAIL_PANEL_HEIGHT = 190,
	TRAINER_DETAIL_MEDIA_PANEL_HEIGHT = 595,
	TRAINER_DETAIL_MODEL_WIDTH = 104,
	TRAINER_DETAIL_MODEL_HEIGHT = 148,
	TRAINER_DETAIL_MAP_WIDTH = 420,
	TRAINER_DETAIL_MAP_HEIGHT = 289,
	TRAINER_DETAIL_MODEL_PREVIEW_WIDTH = 300,
	TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT = 450,
	TRAINER_DETAIL_MAP_PREVIEW_WIDTH = 760,
	TRAINER_DETAIL_MAP_PREVIEW_HEIGHT = 524,
	TRAINER_DETAIL_PREVIEW_PADDING = 5,
	TRAINER_DETAIL_PREVIEW_DURATION = 0.22,
	TRAINER_DETAIL_IMAGE_HINT_TEXT = "Click to enlarge",
	TRAINER_DETAIL_IMAGE_HINT_WIDTH = 112,
	TRAINER_DETAIL_IMAGE_HINT_HEIGHT = 22,
	TRAINER_SCROLL_GAP = 10,
	TRAINER_SCROLL_TRACK_WIDTH = 8,
	TRAINER_SCROLL_THUMB_MIN_HEIGHT = 36,
	TRAINER_SCROLL_STEP = 82,
	TRAINER_SCROLL_SMOOTHING = 16,
	TRAINER_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Bandage_11",
	TRAINER_TEACHES_BUTTON_WIDTH = 142,
	TRAINER_TEACHES_BUTTON_HEIGHT = 26,
	TRAINER_TEACH_ROW_WIDTH = 456,
	TRAINER_TEACH_ROW_COLLAPSED_HEIGHT = 52,
	TRAINER_TEACH_ROW_EXPANDED_HEIGHT = 112,
	TRAINER_TEACH_ROW_GAP = 8,
	TRAINER_TEACH_ICON_SIZE = 34,
	TRAINER_TEACH_LIST_HEIGHT = 530,
	TRAINER_TEACH_ANIMATION_DURATION = 0.20,
	TRAINER_REAGENT_ICON_SIZE = 22,
	TRAINER_REAGENT_ICON_GAP = 5,
}
Constants.TRAINER_TEACHES_PANEL_WIDTH = Constants.TRAINER_DETAIL_PANEL_WIDTH
Constants.TRAINER_TEACHES_PANEL_HEIGHT = Constants.TRAINER_DETAIL_MEDIA_PANEL_HEIGHT
Trainers.Constants = Constants

local TRAINER_DETAIL_IMAGE_HINT_WIDTH = Constants.TRAINER_DETAIL_IMAGE_HINT_WIDTH
local TRAINER_DETAIL_IMAGE_HINT_HEIGHT = Constants.TRAINER_DETAIL_IMAGE_HINT_HEIGHT
local TRAINER_DETAIL_IMAGE_HINT_TEXT = Constants.TRAINER_DETAIL_IMAGE_HINT_TEXT
local TRAINER_DETAIL_MAP_WIDTH = Constants.TRAINER_DETAIL_MAP_WIDTH
local TRAINER_DETAIL_MAP_HEIGHT = Constants.TRAINER_DETAIL_MAP_HEIGHT
local TRAINER_DETAIL_MODEL_WIDTH = Constants.TRAINER_DETAIL_MODEL_WIDTH
local TRAINER_DETAIL_MODEL_HEIGHT = Constants.TRAINER_DETAIL_MODEL_HEIGHT
local TRAINER_DETAIL_MAP_PREVIEW_WIDTH = Constants.TRAINER_DETAIL_MAP_PREVIEW_WIDTH
local TRAINER_DETAIL_MAP_PREVIEW_HEIGHT = Constants.TRAINER_DETAIL_MAP_PREVIEW_HEIGHT
local TRAINER_DETAIL_MODEL_PREVIEW_WIDTH = Constants.TRAINER_DETAIL_MODEL_PREVIEW_WIDTH
local TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT = Constants.TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT
local TRAINER_DETAIL_PREVIEW_PADDING = Constants.TRAINER_DETAIL_PREVIEW_PADDING
local TRAINER_FALLBACK_ICON = Constants.TRAINER_FALLBACK_ICON
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD_SOFT = Shared.Colors.GOLD_SOFT
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local setIcon = Shared.SetIcon
local getSpellTexture = Shared.GetSpellTexture

Shared.RegisterWindowSize("trainers", 560, 270)
Shared.RegisterWindowSize("trainerList", 560, 500)
Shared.RegisterWindowSize("trainerDetail", 570, 390)
Shared.RegisterWindowSize("trainerDetailMedia", 570, 740)
Shared.RegisterWindowSize("trainerDetailModelPreview", 570, 740)
Shared.RegisterWindowSize("trainerDetailMapPreview", 860, 760)
Shared.RegisterWindowSize("trainerTeaches", 570, 740)

Trainers.Factions = {
	{
		id = "horde",
		label = "Horde",
		icon = "Interface\\TargetingFrame\\UI-PVP-Horde",
		iconTexCoord = { 0, 0.59375, 0, 0.5625 },
		accent = { 0.90, 0.18, 0.14 },
	},
	{
		id = "alliance",
		label = "Alliance",
		icon = "Interface\\TargetingFrame\\UI-PVP-Alliance",
		iconTexCoord = { 0, 0.5, 0, 0.59375 },
		accent = { 0.22, 0.48, 0.95 },
	},
}

function Trainers.GetTrainerLocationText(trainer, includeCoords)
	if not trainer then
		return ""
	end

	local location = trainer.zone or ""
	if trainer.area and trainer.area ~= "" then
		location = location ~= "" and (trainer.area .. ", " .. location) or trainer.area
	end

	if includeCoords and trainer.coords and trainer.coords ~= "" then
		location = location ~= "" and (location .. " (" .. trainer.coords .. ")") or trainer.coords
	end

	return location
end

local function getImageSize(imageSize)
	if not imageSize then
		return nil, nil
	end

	return imageSize.width or imageSize[1], imageSize.height or imageSize[2]
end

local function fitImageSize(imageSize, maxWidth, maxHeight)
	local sourceWidth, sourceHeight = getImageSize(imageSize)
	if not sourceWidth or not sourceHeight or sourceWidth <= 0 or sourceHeight <= 0 then
		return maxWidth, maxHeight
	end

	local scale = math.min(maxWidth / sourceWidth, maxHeight / sourceHeight)
	return sourceWidth * scale, sourceHeight * scale
end
Trainers.FitImageSize = fitImageSize

function Trainers.SetTrainerImage(texture, trainer, imageWidth, imageHeight, fallbackSize)
	if trainer and trainer.targetImage then
		local width, height = fitImageSize(trainer.targetImageSize, imageWidth, imageHeight)

		texture:SetSize(width, height)
		texture:SetTexture(trainer.targetImage)
		texture:SetTexCoord(0, 1, 0, 1)
		return
	end

	local iconSize = fallbackSize or math.min(imageWidth, imageHeight)
	texture:SetSize(iconSize, iconSize)
	setIcon(texture, (trainer and trainer.icon) or TRAINER_FALLBACK_ICON)
end

function Trainers.SetTrainerDetailImage(texture, imagePath, imageSize, maxWidth, maxHeight)
	if imagePath then
		local width, height = fitImageSize(imageSize, maxWidth or texture:GetWidth(), maxHeight or texture:GetHeight())

		texture:ClearAllPoints()
		texture:SetPoint("CENTER", texture:GetParent(), "CENTER", 0, 0)
		texture:SetSize(width, height)
		texture:SetTexture(imagePath)
		texture:SetTexCoord(0, 1, 0, 1)
		texture:Show()
		return true, width, height
	end

	texture:SetTexture(nil)
	texture:Hide()
	return false
end

function Trainers.CreateTrainerImageHoverHint(parent)
	local hint = CreateFrame("Frame", nil, parent, ns:GetBackdropTemplate())
	hint:SetSize(TRAINER_DETAIL_IMAGE_HINT_WIDTH, TRAINER_DETAIL_IMAGE_HINT_HEIGHT)
	hint:SetPoint("CENTER", parent, "CENTER", 0, 0)
	hint:SetFrameLevel((parent:GetFrameLevel() or 0) + 2)
	applyBackdrop(hint, BUTTON_BACKDROP, { 0.010, 0.010, 0.012, 0.52 }, { 0.42, 0.36, 0.24, 0.58 })
	hint:Hide()

	local text = hint:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", hint, "CENTER", 0, 0)
	text:SetText(TRAINER_DETAIL_IMAGE_HINT_TEXT)
	setTextColor(text, GOLD_SOFT)

	return hint
end

function Trainers.GetTrainerImagePreviewConfig(imageKind, trainer)
	if imageKind == "map" then
		local startWidth, startHeight = fitImageSize(trainer and trainer.mapImageSize, TRAINER_DETAIL_MAP_WIDTH, TRAINER_DETAIL_MAP_HEIGHT)
		local targetWidth, targetHeight = fitImageSize(trainer and trainer.mapImageSize, TRAINER_DETAIL_MAP_PREVIEW_WIDTH, TRAINER_DETAIL_MAP_PREVIEW_HEIGHT)

		return {
			windowName = "trainerDetailMapPreview",
			startWidth = startWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
			startHeight = startHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
			targetWidth = targetWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
			targetHeight = targetHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		}
	end

	local startWidth, startHeight = fitImageSize(trainer and trainer.modelImageSize, TRAINER_DETAIL_MODEL_WIDTH, TRAINER_DETAIL_MODEL_HEIGHT)
	local targetWidth, targetHeight = fitImageSize(trainer and trainer.modelImageSize, TRAINER_DETAIL_MODEL_PREVIEW_WIDTH, TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT)

	return {
		windowName = "trainerDetailModelPreview",
		startWidth = startWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		startHeight = startHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		targetWidth = targetWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		targetHeight = targetHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
	}
end

function Trainers.Clamp(value, minimum, maximum)
	if value < minimum then
		return minimum
	end

	if value > maximum then
		return maximum
	end

	return value
end

function Trainers.HasTrainerTeaches(trainer)
	return trainer and trainer.teaches and #trainer.teaches > 0
end

function Trainers.GetTrainerTeachName(teach)
	if not teach then
		return ""
	end

	if teach.rank and teach.rank ~= "" then
		return teach.name .. " - " .. teach.rank
	end

	return teach.name or ""
end

local function formatFirstAidSkill(skill)
	if not skill or skill <= 0 then
		return "No prior skill"
	end

	return "First Aid " .. tostring(skill)
end

function Trainers.FormatTrainerTeachReagents(teach)
	if not teach or not teach.reagents or #teach.reagents == 0 then
		return "None"
	end

	local reagents = {}
	for index, reagent in ipairs(teach.reagents) do
		reagents[index] = reagent.name .. " x" .. tostring(reagent.quantity or 1)
	end

	return table.concat(reagents, ", ")
end

function Trainers.FormatTrainerTeachCreates(teach)
	if not teach or not teach.creates then
		return nil
	end

	local quantity = teach.creates.quantity or 1
	if quantity > 1 then
		return teach.creates.name .. " x" .. tostring(quantity)
	end

	return teach.creates.name
end

local function getItemIcon(itemID, fallback)
	if itemID then
		local icon
		if C_Item and C_Item.GetItemIconByID then
			icon = C_Item.GetItemIconByID(itemID)
		elseif GetItemIcon then
			icon = GetItemIcon(itemID)
		end

		if icon then
			return icon
		end
	end

	return fallback or "Interface\\Icons\\INV_Misc_QuestionMark"
end
Trainers.GetItemIcon = getItemIcon

function Trainers.GetTrainerTeachIcon(teach)
	local fallback = getSpellTexture(teach and teach.spellID, (teach and teach.icon) or TRAINER_FALLBACK_ICON)
	if teach and teach.creates and teach.creates.itemID then
		return getItemIcon(teach.creates.itemID, fallback)
	end

	return fallback
end

function Trainers.ShowItemTooltip(frame)
	if not frame or not GameTooltip then
		return
	end

	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	if frame.itemID then
		if GameTooltip.SetItemByID then
			GameTooltip:SetItemByID(frame.itemID)
		else
			GameTooltip:SetHyperlink("item:" .. tostring(frame.itemID))
		end
	elseif frame.reagentName then
		GameTooltip:SetText(frame.reagentName)
	end
	GameTooltip:Show()
end

function Trainers.HideItemTooltip()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

function Trainers.GetTrainerTeachLines(teach)
	if not teach then
		return "", "", "", ""
	end

	local requirementLine = "Train: " .. formatFirstAidSkill(teach.requiredSkill)
	if teach.characterLevel then
		requirementLine = requirementLine .. "   Level " .. tostring(teach.characterLevel)
	end

	if teach.type == "rank" then
		return requirementLine,
			"Cap: First Aid " .. tostring(teach.skillCap or ""),
			teach.description or "",
			""
	end

	if teach.itemRequiredSkill then
		requirementLine = requirementLine .. "   Use: " .. formatFirstAidSkill(teach.itemRequiredSkill)
	end

	return requirementLine, "", "", ""
end
