local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared

local FACTION_BUTTON_WIDTH = 112
local FACTION_BUTTON_HEIGHT = 32
local FACTION_BUTTON_GAP = 10
local TRAINER_ROW_WIDTH = 470
local TRAINER_ROW_HEIGHT = 78
local TRAINER_ROW_GAP = 8
local TRAINER_IMAGE_WIDTH = 72
local TRAINER_IMAGE_HEIGHT = 66
local TRAINER_LIST_HEIGHT = 300
local TRAINER_DETAIL_PANEL_WIDTH = 492
local TRAINER_DETAIL_PANEL_HEIGHT = 190
local TRAINER_DETAIL_MEDIA_PANEL_HEIGHT = 595
local TRAINER_DETAIL_MODEL_WIDTH = 104
local TRAINER_DETAIL_MODEL_HEIGHT = 148
local TRAINER_DETAIL_MAP_WIDTH = 420
local TRAINER_DETAIL_MAP_HEIGHT = 289
local TRAINER_DETAIL_MODEL_PREVIEW_WIDTH = 300
local TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT = 450
local TRAINER_DETAIL_MAP_PREVIEW_WIDTH = 760
local TRAINER_DETAIL_MAP_PREVIEW_HEIGHT = 524
local TRAINER_DETAIL_PREVIEW_PADDING = 5
local TRAINER_DETAIL_PREVIEW_DURATION = 0.22
local TRAINER_DETAIL_IMAGE_HINT_TEXT = "Click to enlarge"
local TRAINER_DETAIL_IMAGE_HINT_WIDTH = 112
local TRAINER_DETAIL_IMAGE_HINT_HEIGHT = 22
local TRAINER_SCROLL_GAP = 10
local TRAINER_SCROLL_TRACK_WIDTH = 8
local TRAINER_SCROLL_THUMB_MIN_HEIGHT = 36
local TRAINER_SCROLL_STEP = 82
local TRAINER_SCROLL_SMOOTHING = 16
local TRAINER_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Bandage_11"
local SCREEN_PADDING_X = Shared.SCREEN_PADDING_X
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD = Shared.Colors.GOLD
local GOLD_SOFT = Shared.Colors.GOLD_SOFT
local TEXT = Shared.Colors.TEXT
local TEXT_DIM = Shared.Colors.TEXT_DIM
local BORDER_BRIGHT = Shared.Colors.BORDER_BRIGHT
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local easeOutCubic = Shared.EaseOutCubic
local setIcon = Shared.SetIcon
local setTextureCoordinates = Shared.SetTextureCoordinates
local createBody = Shared.CreateBody
local setBodyOffset = Shared.SetBodyOffset
local createTint = Shared.CreateTint
local createView = Shared.CreateView

Shared.RegisterWindowSize("trainers", 560, 270)
Shared.RegisterWindowSize("trainerList", 560, 500)
Shared.RegisterWindowSize("trainerDetail", 570, 390)
Shared.RegisterWindowSize("trainerDetailMedia", 570, 740)
Shared.RegisterWindowSize("trainerDetailModelPreview", 570, 740)
Shared.RegisterWindowSize("trainerDetailMapPreview", 860, 760)

local TRAINER_FACTIONS = {
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

local function getTrainerLocationText(trainer, includeCoords)
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

local function setTrainerImage(texture, trainer, imageWidth, imageHeight, fallbackSize)
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

local function setTrainerDetailImage(texture, imagePath, imageSize, maxWidth, maxHeight)
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

local function createTrainerImageHoverHint(parent)
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

local function getTrainerImagePreviewConfig(imageKind, trainer)
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

local function clamp(value, minimum, maximum)
	if value < minimum then
		return minimum
	end

	if value > maximum then
		return maximum
	end

	return value
end

function ProfessionMenu:CreateTrainerMenuView()
	local view = createView(self.stage, "ProfessionTrainersView")
	self.views.trainers = view

	local title, subtitle = self:CreateHeader(view, "Trainers", "Choose a faction", function()
		self:GoBackToProfessionDetail()
	end)
	self.trainerHeaderTitle = title
	self.trainerHeaderSubtitle = subtitle

	local factionRow = CreateFrame("Frame", nil, view)
	factionRow:SetSize((#TRAINER_FACTIONS * FACTION_BUTTON_WIDTH) + ((#TRAINER_FACTIONS - 1) * FACTION_BUTTON_GAP), FACTION_BUTTON_HEIGHT)
	factionRow:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_PADDING_X, -78)

	self.trainerFactionButtons = {}
	for index, faction in ipairs(TRAINER_FACTIONS) do
		local button = self:CreateTrainerFactionButton(factionRow, faction)
		button:SetPoint("TOPLEFT", factionRow, "TOPLEFT", (index - 1) * (FACTION_BUTTON_WIDTH + FACTION_BUTTON_GAP), 0)
		table.insert(self.trainerFactionButtons, button)
	end

	local scrollFrame = CreateFrame("ScrollFrame", nil, view)
	scrollFrame:SetSize(TRAINER_ROW_WIDTH, TRAINER_LIST_HEIGHT)
	scrollFrame:SetPoint("TOPLEFT", factionRow, "BOTTOMLEFT", 0, -14)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:Hide()

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(TRAINER_ROW_WIDTH, TRAINER_LIST_HEIGHT)
	scrollFrame:SetScrollChild(content)
	scrollFrame:SetScript("OnMouseWheel", function(frame, delta)
		self:SetTrainerScrollTarget((self.trainerScrollTarget or frame:GetVerticalScroll() or 0) - (delta * TRAINER_SCROLL_STEP))
	end)

	local scrollTrack = CreateFrame("Frame", nil, view)
	scrollTrack:SetSize(TRAINER_SCROLL_TRACK_WIDTH, TRAINER_LIST_HEIGHT)
	scrollTrack:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", TRAINER_SCROLL_GAP, 0)
	scrollTrack:EnableMouse(true)
	scrollTrack:RegisterForDrag("LeftButton")
	scrollTrack:Hide()

	local trackTexture = scrollTrack:CreateTexture(nil, "BACKGROUND")
	trackTexture:SetAllPoints(scrollTrack)
	colorTexture(trackTexture, 0.03, 0.03, 0.035, 0.74)

	local scrollThumb = scrollTrack:CreateTexture(nil, "OVERLAY")
	scrollThumb:SetWidth(TRAINER_SCROLL_TRACK_WIDTH)
	scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, 0)
	colorTexture(scrollThumb, 0.88, 0.72, 0.24, 0.96)
	scrollTrack:SetScript("OnMouseDown", function(track, button)
		if button ~= "LeftButton" then
			return
		end

		self:StartTrainerScrollDrag(track)
	end)
	scrollTrack:SetScript("OnMouseUp", function()
		self:StopTrainerScrollDrag()
	end)
	scrollTrack:SetScript("OnDragStart", function(track)
		self:StartTrainerScrollDrag(track)
	end)
	scrollTrack:SetScript("OnDragStop", function()
		self:StopTrainerScrollDrag()
	end)

	local scrollAnimator = CreateFrame("Frame", nil, view)
	scrollAnimator:Hide()

	self.trainerButtons = {}
	self.trainerContent = content
	self.trainerScrollFrame = scrollFrame
	self.trainerScrollTrack = scrollTrack
	self.trainerScrollThumb = scrollThumb
	self.trainerScrollAnimator = scrollAnimator
	self.trainerScrollTarget = 0
	self.trainerScrollMax = 0
	self.trainerDraggingScroll = false
end

function ProfessionMenu:CreateTrainerFactionButton(parent, faction)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(FACTION_BUTTON_WIDTH, FACTION_BUTTON_HEIGHT)
	button:RegisterForClicks("LeftButtonUp")
	button.faction = faction
	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.22, 0.22, 0.23, 1 })

	local highlight = createTint(button, faction.accent[1], faction.accent[2], faction.accent[3], 0.24)
	local body = createBody(button)

	local stripe = body:CreateTexture(nil, "ARTWORK")
	stripe:SetPoint("TOPLEFT", body, "TOPLEFT", 5, -5)
	stripe:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 5, 5)
	stripe:SetWidth(2)
	colorTexture(stripe, faction.accent[1], faction.accent[2], faction.accent[3], 0.84)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(18, 18)
	icon:SetPoint("LEFT", body, "LEFT", 15, 0)
	setIcon(icon, faction.icon)
	setTextureCoordinates(icon, faction.iconTexCoord)

	local label = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	label:SetWidth(68)
	label:SetJustifyH("LEFT")
	label:SetText(faction.label)
	setTextColor(label, TEXT)

	button.highlight = highlight
	button.label = label
	button:SetScript("OnEnter", function(factionButton)
		self:SetTrainerFactionButtonState(factionButton, factionButton.faction.id == self.selectedTrainerFactionID, true)
	end)
	button:SetScript("OnLeave", function(factionButton)
		self:SetTrainerFactionButtonState(factionButton, factionButton.faction.id == self.selectedTrainerFactionID, false)
	end)
	button:SetScript("OnMouseDown", function(factionButton)
		setBodyOffset(factionButton, 1, -1)
	end)
	button:SetScript("OnMouseUp", function(factionButton)
		setBodyOffset(factionButton, 0, 0)
	end)
	button:SetScript("OnClick", function(factionButton)
		self:SelectTrainerFaction(factionButton.faction.id)
	end)

	return button
end

function ProfessionMenu:CreateTrainerButton(parent)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(TRAINER_ROW_WIDTH, TRAINER_ROW_HEIGHT)
	button:RegisterForClicks("LeftButtonUp")
	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.22, 0.22, 0.23, 1 })

	local highlight = createTint(button, GOLD[1], GOLD[2], GOLD[3], 0.18)
	local body = createBody(button)

	local stripe = body:CreateTexture(nil, "ARTWORK")
	stripe:SetPoint("TOPLEFT", body, "TOPLEFT", 5, -5)
	stripe:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 5, 5)
	stripe:SetWidth(2)
	colorTexture(stripe, GOLD[1], GOLD[2], GOLD[3], 0.80)

	local imageFrame = CreateFrame("Frame", nil, body)
	imageFrame:SetSize(TRAINER_IMAGE_WIDTH, TRAINER_IMAGE_HEIGHT)
	imageFrame:SetPoint("LEFT", body, "LEFT", 14, 0)

	local image = imageFrame:CreateTexture(nil, "OVERLAY")
	image:SetPoint("CENTER", imageFrame, "CENTER", 0, 0)

	local name = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("TOPLEFT", imageFrame, "TOPRIGHT", 15, -17)
	name:SetWidth(308)
	name:SetJustifyH("LEFT")
	setTextColor(name, GOLD)

	local location = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	location:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
	location:SetWidth(316)
	location:SetJustifyH("LEFT")
	setTextColor(location, TEXT_DIM)

	local chevron = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	chevron:SetPoint("RIGHT", body, "RIGHT", -12, 0)
	chevron:SetText(">")
	chevron:SetTextColor(0.56, 0.53, 0.46, 1)

	button.highlight = highlight
	button.stripe = stripe
	button.image = image
	button.name = name
	button.location = location
	button.chevron = chevron
	button:SetScript("OnEnter", function(trainerButton)
		self:SetTrainerButtonState(trainerButton, true)
	end)
	button:SetScript("OnLeave", function(trainerButton)
		self:SetTrainerButtonState(trainerButton, false)
	end)
	button:SetScript("OnMouseDown", function(trainerButton)
		setBodyOffset(trainerButton, 1, -1)
	end)
	button:SetScript("OnMouseUp", function(trainerButton)
		setBodyOffset(trainerButton, 0, 0)
	end)
	button:SetScript("OnClick", function(trainerButton)
		self:GoToTrainerDetail(trainerButton.trainer)
	end)

	return button
end

function ProfessionMenu:CreateTrainerDetailView()
	local view = createView(self.stage, "TrainerDetailView")
	self.views.trainerDetail = view

	local title, subtitle = self:CreateHeader(view, "Trainer", "Details", function()
		self:GoBackToTrainerList()
	end)
	self.trainerDetailHeaderTitle = title
	self.trainerDetailHeaderSubtitle = subtitle

	local panel = CreateFrame("Frame", nil, view, ns:GetBackdropTemplate())
	panel:SetSize(TRAINER_DETAIL_PANEL_WIDTH, TRAINER_DETAIL_PANEL_HEIGHT)
	panel:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_PADDING_X, -78)
	applyBackdrop(panel, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.82 }, { 0.22, 0.22, 0.23, 1 })

	local imageFrame = CreateFrame("Frame", nil, panel)
	imageFrame:SetSize(92, 84)
	imageFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)

	local image = imageFrame:CreateTexture(nil, "OVERLAY")
	image:SetPoint("CENTER", imageFrame, "CENTER", 0, 0)

	local name = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	name:SetPoint("TOPLEFT", imageFrame, "TOPRIGHT", 16, -2)
	name:SetWidth(210)
	name:SetJustifyH("LEFT")
	setTextColor(name, GOLD)

	local role = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	role:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
	role:SetWidth(210)
	role:SetJustifyH("LEFT")
	role:SetTextColor(0.74, 0.70, 0.60, 1)

	local locationLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	locationLabel:SetPoint("TOPLEFT", imageFrame, "BOTTOMLEFT", 0, -18)
	locationLabel:SetText("Location")
	setTextColor(locationLabel, GOLD_SOFT)

	local waypointButton = CreateFrame("Button", nil, panel, ns:GetBackdropTemplate())
	waypointButton:SetSize(84, 22)
	waypointButton:RegisterForClicks("LeftButtonUp")
	applyBackdrop(waypointButton, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.30, 0.30, 0.31, 1 })
	waypointButton:Hide()

	local waypointLabel = waypointButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	waypointLabel:SetPoint("CENTER", waypointButton, "CENTER", 0, 0)
	waypointLabel:SetText("waypoint")
	setTextColor(waypointLabel, TEXT_DIM)

	local location = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	location:SetPoint("TOPLEFT", locationLabel, "BOTTOMLEFT", 0, -5)
	location:SetWidth(318)
	location:SetJustifyH("LEFT")
	setTextColor(location, TEXT)

	local modelFrame = CreateFrame("Frame", nil, panel)
	modelFrame:SetSize(TRAINER_DETAIL_MODEL_WIDTH, TRAINER_DETAIL_MODEL_HEIGHT)
	modelFrame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -14)

	local model = modelFrame:CreateTexture(nil, "OVERLAY")
	model:SetPoint("CENTER", modelFrame, "CENTER", 0, 0)
	model:Hide()

	local modelButton = CreateFrame("Button", nil, modelFrame)
	modelButton:SetAllPoints(modelFrame)
	modelButton:EnableMouse(true)
	modelButton:RegisterForClicks("LeftButtonUp")
	modelButton:Hide()
	local modelHint = createTrainerImageHoverHint(modelButton)
	modelButton:SetScript("OnEnter", function(button)
		if not self.trainerImagePreviewOverlay or not self.trainerImagePreviewOverlay:IsShown() then
			button.enlargeHint:Show()
		end
	end)
	modelButton:SetScript("OnLeave", function(button)
		button.enlargeHint:Hide()
	end)
	modelButton:SetScript("OnClick", function()
		if self.selectedTrainer and self.selectedTrainer.modelImage then
			self:OpenTrainerImagePreview(self.selectedTrainer.modelImage, "model")
		end
	end)
	modelButton.enlargeHint = modelHint

	local npcID = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	npcID:SetPoint("TOP", modelFrame, "BOTTOM", 0, -8)
	npcID:SetWidth(140)
	npcID:SetJustifyH("CENTER")
	setTextColor(npcID, TEXT_DIM)

	local mapFrame = CreateFrame("Frame", nil, panel)
	mapFrame:SetSize(TRAINER_DETAIL_MAP_WIDTH, TRAINER_DETAIL_MAP_HEIGHT)
	mapFrame:SetPoint("TOPLEFT", location, "BOTTOMLEFT", 0, -12)
	mapFrame:Hide()

	local map = mapFrame:CreateTexture(nil, "OVERLAY")
	map:SetAllPoints(mapFrame)
	map:Hide()

	local mapButton = CreateFrame("Button", nil, mapFrame)
	mapButton:SetAllPoints(mapFrame)
	mapButton:EnableMouse(true)
	mapButton:RegisterForClicks("LeftButtonUp")
	mapButton:Hide()
	local mapHint = createTrainerImageHoverHint(mapButton)
	mapButton:SetScript("OnEnter", function(button)
		if not self.trainerImagePreviewOverlay or not self.trainerImagePreviewOverlay:IsShown() then
			button.enlargeHint:Show()
		end
	end)
	mapButton:SetScript("OnLeave", function(button)
		button.enlargeHint:Hide()
	end)
	mapButton:SetScript("OnClick", function()
		if self.selectedTrainer and self.selectedTrainer.mapImage then
			self:OpenTrainerImagePreview(self.selectedTrainer.mapImage, "map")
		end
	end)
	mapButton.enlargeHint = mapHint

	local previewOverlay = CreateFrame("Button", nil, view)
	previewOverlay:SetAllPoints(view)
	previewOverlay:SetFrameLevel(view:GetFrameLevel() + 80)
	previewOverlay:EnableMouse(true)
	previewOverlay:RegisterForClicks("LeftButtonUp")
	previewOverlay:Hide()

	local previewDim = previewOverlay:CreateTexture(nil, "BACKGROUND")
	previewDim:SetAllPoints(previewOverlay)
	colorTexture(previewDim, 0, 0, 0, 0.74)

	local previewFrame = CreateFrame("Button", nil, previewOverlay, ns:GetBackdropTemplate())
	previewFrame:EnableMouse(true)
	previewFrame:RegisterForClicks("LeftButtonUp")
	previewFrame:SetFrameLevel(previewOverlay:GetFrameLevel() + 2)
	applyBackdrop(previewFrame, BUTTON_BACKDROP, { 0.010, 0.010, 0.012, 0.96 }, { 0.48, 0.42, 0.30, 1 })
	previewFrame:SetScript("OnClick", function() end)

	local previewImage = previewFrame:CreateTexture(nil, "OVERLAY")
	previewImage:SetPoint("TOPLEFT", previewFrame, "TOPLEFT", TRAINER_DETAIL_PREVIEW_PADDING, -TRAINER_DETAIL_PREVIEW_PADDING)
	previewImage:SetPoint("BOTTOMRIGHT", previewFrame, "BOTTOMRIGHT", -TRAINER_DETAIL_PREVIEW_PADDING, TRAINER_DETAIL_PREVIEW_PADDING)
	previewImage:SetTexCoord(0, 1, 0, 1)

	previewOverlay:SetScript("OnClick", function()
		self:CloseTrainerImagePreview()
	end)

	self.trainerDetailPanel = panel
	self.trainerDetailImageFrame = imageFrame
	self.trainerDetailImage = image
	self.trainerDetailName = name
	self.trainerDetailRole = role
	self.trainerDetailLocationLabel = locationLabel
	self.trainerDetailLocation = location
	self.trainerDetailModel = model
	self.trainerDetailMap = map
	self.trainerDetailModelButton = modelButton
	self.trainerDetailMapButton = mapButton
	self.trainerDetailModelHint = modelHint
	self.trainerDetailMapHint = mapHint
	self.trainerDetailMapFrame = mapFrame
	self.trainerDetailModelFrame = modelFrame
	self.trainerDetailNpcID = npcID
	self.trainerDetailWaypointButton = waypointButton
	self.trainerImagePreviewOverlay = previewOverlay
	self.trainerImagePreviewFrame = previewFrame
	self.trainerImagePreviewImage = previewImage
end

function ProfessionMenu:GoToTrainerMenu()
	self:RefreshTrainerMenu()
	self:ResizeWindow("trainers")
	self:TransitionTo(self.views.trainers, 1, "trainers")
end

function ProfessionMenu:GetSelectedProfessionTrainers(factionID)
	local profession = self.selectedProfession or self.professions[1]
	local professionID = profession and profession.id
	local trainerData = ns.ProfessionData and ns.ProfessionData.trainerData
	local professionData = trainerData and professionID and trainerData[professionID]

	return (professionData and factionID and professionData[factionID]) or {}
end

function ProfessionMenu:GetTrainerListWindowName()
	local trainers = self:GetSelectedProfessionTrainers(self.selectedTrainerFactionID)
	return #trainers > 0 and "trainerList" or "trainers"
end

function ProfessionMenu:GetTrainerDetailWindowName(trainer)
	return trainer and (trainer.modelImage or trainer.mapImage) and "trainerDetailMedia" or "trainerDetail"
end

function ProfessionMenu:RefreshTrainerMenu()
	local profession = self.selectedProfession or self.professions[1]
	local professionName = profession and profession.name or "Profession"

	self.trainerHeaderTitle:SetText(professionName .. " Trainers")
	self.trainerHeaderSubtitle:SetText("Choose a faction")
	self.selectedTrainerFactionID = nil
	self.selectedTrainer = nil

	if self.trainerScrollFrame then
		self.trainerScrollFrame:SetScript("OnUpdate", nil)
		self:SetTrainerScrollTarget(0, true)
		self.trainerScrollFrame:SetAlpha(0)
		self.trainerScrollFrame:Hide()
	end

	if self.trainerScrollTrack then
		self.trainerScrollTrack:SetAlpha(0)
		self.trainerScrollTrack:Hide()
	end

	self:HideTrainerButtons()
	self:RefreshTrainerFactions()
end

function ProfessionMenu:HideTrainerButtons()
	for _, button in ipairs(self.trainerButtons) do
		button:Hide()
	end
end

function ProfessionMenu:RefreshTrainerList()
	local trainers = self:GetSelectedProfessionTrainers(self.selectedTrainerFactionID)
	local faction = self:GetTrainerFaction(self.selectedTrainerFactionID)
	local accent = (faction and faction.accent) or GOLD
	local contentHeight = math.max(TRAINER_LIST_HEIGHT, (#trainers * TRAINER_ROW_HEIGHT) + (math.max(#trainers - 1, 0) * TRAINER_ROW_GAP))

	self.trainerContent:SetHeight(contentHeight)
	self.trainerScrollMax = math.max(contentHeight - TRAINER_LIST_HEIGHT, 0)

	for index, trainer in ipairs(trainers) do
		local button = self.trainerButtons[index]
		if not button then
			button = self:CreateTrainerButton(self.trainerContent)
			self.trainerButtons[index] = button
		end

		button.trainer = trainer
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", self.trainerContent, "TOPLEFT", 0, -((index - 1) * (TRAINER_ROW_HEIGHT + TRAINER_ROW_GAP)))
		colorTexture(button.stripe, accent[1], accent[2], accent[3], 0.84)
		setTrainerImage(button.image, trainer, TRAINER_IMAGE_WIDTH, TRAINER_IMAGE_HEIGHT, 32)
		button.name:SetText(trainer.name)
		button.location:SetText(getTrainerLocationText(trainer, false))
		self:SetTrainerButtonState(button, false)
		button:Show()
	end

	for index = #trainers + 1, #self.trainerButtons do
		self.trainerButtons[index]:Hide()
	end

	if self.trainerScrollFrame then
		self:SetTrainerScrollTarget(0, true)
		if self.trainerScrollFrame.UpdateScrollChildRect then
			self.trainerScrollFrame:UpdateScrollChildRect()
		end
	end

	self:RefreshTrainerScrollIndicator()

	return #trainers
end

function ProfessionMenu:SetTrainerScrollTarget(target, immediate)
	if not self.trainerScrollFrame then
		return
	end

	self.trainerScrollTarget = clamp(target or 0, 0, self.trainerScrollMax or 0)

	if immediate then
		self.trainerScrollFrame:SetVerticalScroll(self.trainerScrollTarget)
		self:RefreshTrainerScrollIndicator()
		return
	end

	self:StartTrainerSmoothScroll()
end

function ProfessionMenu:StartTrainerSmoothScroll()
	if not self.trainerScrollAnimator then
		return
	end

	self.trainerScrollAnimator:SetScript("OnUpdate", function(_, elapsed)
		self:UpdateTrainerSmoothScroll(elapsed)
	end)
	self.trainerScrollAnimator:Show()
end

function ProfessionMenu:UpdateTrainerSmoothScroll(elapsed)
	if not self.trainerScrollFrame then
		return
	end

	local current = self.trainerScrollFrame:GetVerticalScroll() or 0
	local target = self.trainerScrollTarget or 0
	local progress = math.min(elapsed * TRAINER_SCROLL_SMOOTHING, 1)
	local nextScroll = current + ((target - current) * progress)

	if math.abs(target - nextScroll) < 0.5 then
		nextScroll = target
		if self.trainerScrollAnimator then
			self.trainerScrollAnimator:SetScript("OnUpdate", nil)
			self.trainerScrollAnimator:Hide()
		end
	end

	self.trainerScrollFrame:SetVerticalScroll(nextScroll)
	self:RefreshTrainerScrollIndicator()
end

function ProfessionMenu:StartTrainerScrollDrag(track)
	if not track or (self.trainerScrollMax or 0) <= 0 then
		return
	end

	self.trainerDraggingScroll = true
	if self.trainerScrollAnimator then
		self.trainerScrollAnimator:SetScript("OnUpdate", nil)
		self.trainerScrollAnimator:Hide()
	end

	track:SetScript("OnUpdate", function(activeTrack)
		self:UpdateTrainerScrollFromCursor(activeTrack)
	end)
	self:UpdateTrainerScrollFromCursor(track)
end

function ProfessionMenu:StopTrainerScrollDrag()
	self.trainerDraggingScroll = false
	if self.trainerScrollTrack then
		self.trainerScrollTrack:SetScript("OnUpdate", nil)
	end
end

function ProfessionMenu:UpdateTrainerScrollFromCursor(track)
	if not track or not self.trainerScrollFrame then
		return
	end

	local _, cursorY = GetCursorPosition()
	local scale = track:GetEffectiveScale() or 1
	local top = track:GetTop()
	local height = track:GetHeight() or TRAINER_LIST_HEIGHT
	if not cursorY or not top or height <= 0 then
		return
	end

	local y = cursorY / scale
	local thumbHeight = self.trainerScrollThumb and (self.trainerScrollThumb:GetHeight() or TRAINER_SCROLL_THUMB_MIN_HEIGHT) or TRAINER_SCROLL_THUMB_MIN_HEIGHT
	local travel = math.max(height - thumbHeight, 1)
	local offset = clamp(top - y - (thumbHeight / 2), 0, travel)
	local target = (offset / travel) * (self.trainerScrollMax or 0)

	self:SetTrainerScrollTarget(target, true)
end

function ProfessionMenu:RefreshTrainerScrollIndicator()
	if not self.trainerScrollTrack or not self.trainerScrollThumb then
		return
	end

	local maxScroll = self.trainerScrollMax or 0
	if maxScroll <= 0 then
		self.trainerScrollTrack:Hide()
		return
	end

	local contentHeight = maxScroll + TRAINER_LIST_HEIGHT
	local thumbHeight = math.max(TRAINER_SCROLL_THUMB_MIN_HEIGHT, TRAINER_LIST_HEIGHT * (TRAINER_LIST_HEIGHT / contentHeight))
	local current = self.trainerScrollFrame and (self.trainerScrollFrame:GetVerticalScroll() or 0) or 0
	local travel = TRAINER_LIST_HEIGHT - thumbHeight
	local offset = maxScroll > 0 and (current / maxScroll) * travel or 0

	self.trainerScrollThumb:SetHeight(thumbHeight)
	self.trainerScrollThumb:ClearAllPoints()
	self.trainerScrollThumb:SetPoint("TOP", self.trainerScrollTrack, "TOP", 0, -offset)
	self.trainerScrollTrack:Show()
end

function ProfessionMenu:GetTrainerFaction(factionID)
	for _, faction in ipairs(TRAINER_FACTIONS) do
		if faction.id == factionID then
			return faction
		end
	end
end

function ProfessionMenu:SetTrainerFactionButtonState(button, selected, hovered)
	local accent = button.faction.accent
	local borderColor = selected and { accent[1], accent[2], accent[3], 1 } or (hovered and BORDER_BRIGHT or { 0.22, 0.22, 0.23, 1 })

	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, selected and 0.96 or 0.90 }, borderColor)
	button.highlight:SetAlpha(selected and 0.58 or (hovered and 0.34 or 0))

	if selected then
		button.label:SetTextColor(1, 0.93, 0.66, 1)
	elseif hovered then
		button.label:SetTextColor(1, 0.96, 0.82, 1)
	else
		setTextColor(button.label, TEXT)
	end
end

function ProfessionMenu:RefreshTrainerFactions()
	for _, button in ipairs(self.trainerFactionButtons) do
		self:SetTrainerFactionButtonState(button, button.faction.id == self.selectedTrainerFactionID, false)
	end
end

function ProfessionMenu:SelectTrainerFaction(factionID)
	self.selectedTrainerFactionID = factionID
	self:RefreshTrainerFactions()
	self:RefreshTrainerList()
	self:ResizeWindow(self:GetTrainerListWindowName())
	self:AnimateTrainerContent()
end

function ProfessionMenu:AnimateTrainerContent()
	local content = self.trainerScrollFrame
	if not content then
		return
	end

	content:SetScript("OnUpdate", nil)
	content:SetAlpha(0)
	content:Show()
	content.animationElapsed = 0
	content:SetScript("OnUpdate", function(frame, elapsed)
		frame.animationElapsed = frame.animationElapsed + elapsed
		local progress = math.min(frame.animationElapsed / 0.18, 1)
		local alpha = easeOutCubic(progress)
		frame:SetAlpha(alpha)
		if self.trainerScrollTrack and (self.trainerScrollMax or 0) > 0 then
			self.trainerScrollTrack:SetAlpha(alpha)
			self.trainerScrollTrack:Show()
		end

		if progress >= 1 then
			frame:SetScript("OnUpdate", nil)
			frame:SetAlpha(1)
			if self.trainerScrollTrack and (self.trainerScrollMax or 0) > 0 then
				self.trainerScrollTrack:SetAlpha(1)
			end
		end
	end)
end

function ProfessionMenu:SetTrainerButtonState(button, hovered)
	local faction = self:GetTrainerFaction(self.selectedTrainerFactionID)
	local accent = (faction and faction.accent) or GOLD
	local borderColor = hovered and BORDER_BRIGHT or { 0.22, 0.22, 0.23, 1 }

	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, hovered and 0.96 or 0.90 }, borderColor)
	button.highlight:SetAlpha(hovered and 0.32 or 0)
	button.chevron:SetTextColor(hovered and 0.95 or 0.56, hovered and 0.83 or 0.53, hovered and 0.44 or 0.46, 1)

	if hovered then
		button.name:SetTextColor(1, 0.93, 0.66, 1)
		button.location:SetTextColor(0.82, 0.78, 0.66, 1)
	else
		setTextColor(button.name, GOLD)
		setTextColor(button.location, TEXT_DIM)
	end

	colorTexture(button.stripe, accent[1], accent[2], accent[3], 0.84)
end

function ProfessionMenu:GoToTrainerDetail(trainer)
	if not trainer then
		return
	end

	self.selectedTrainer = trainer
	self:RefreshTrainerDetail()
	self:ResizeWindow(self:GetTrainerDetailWindowName(trainer))
	self:TransitionTo(self.views.trainerDetail, 1, self:GetTrainerDetailWindowName(trainer))
end

function ProfessionMenu:GoBackToTrainerList()
	self:CloseTrainerImagePreview(true)
	self:RefreshTrainerFactions()
	self:RefreshTrainerList()
	self:ResizeWindow(self:GetTrainerListWindowName())
	self:TransitionTo(self.views.trainers, -1, self:GetTrainerListWindowName())
end

function ProfessionMenu:SetTrainerImagePreviewProgress(config, amount)
	local frame = self.trainerImagePreviewFrame
	local overlay = self.trainerImagePreviewOverlay
	if not frame or not overlay or not config then
		return
	end

	local width = config.startWidth + ((config.targetWidth - config.startWidth) * amount)
	local height = config.startHeight + ((config.targetHeight - config.startHeight) * amount)

	self.trainerImagePreviewProgress = amount
	overlay:SetAlpha(amount)
	frame:SetSize(width, height)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", overlay, "CENTER", 0, 0)
end

function ProfessionMenu:HideTrainerImageHoverHints()
	if self.trainerDetailModelHint then
		self.trainerDetailModelHint:Hide()
	end

	if self.trainerDetailMapHint then
		self.trainerDetailMapHint:Hide()
	end
end

function ProfessionMenu:OpenTrainerImagePreview(imagePath, imageKind)
	if not imagePath or not self.trainerImagePreviewOverlay or not self.trainerImagePreviewFrame or not self.trainerImagePreviewImage then
		return
	end

	local config = getTrainerImagePreviewConfig(imageKind, self.selectedTrainer)
	self:HideTrainerImageHoverHints()
	self.trainerImagePreviewKind = imageKind
	self.trainerImagePreviewOverlay:SetScript("OnUpdate", nil)
	self.trainerImagePreviewImage:SetTexture(imagePath)
	self.trainerImagePreviewImage:SetTexCoord(0, 1, 0, 1)
	self.trainerImagePreviewOverlay:SetAlpha(0)
	self.trainerImagePreviewOverlay:Show()
	self:SetTrainerImagePreviewProgress(config, 0)
	self:ResizeWindow(config.windowName)

	local elapsedTime = 0
	self.trainerImagePreviewOverlay:SetScript("OnUpdate", function(overlay, elapsed)
		elapsedTime = elapsedTime + elapsed
		local progress = math.min(elapsedTime / TRAINER_DETAIL_PREVIEW_DURATION, 1)
		self:SetTrainerImagePreviewProgress(config, easeOutCubic(progress))

		if progress >= 1 then
			overlay:SetScript("OnUpdate", nil)
			self:SetTrainerImagePreviewProgress(config, 1)
		end
	end)
end

function ProfessionMenu:CloseTrainerImagePreview(immediate)
	local overlay = self.trainerImagePreviewOverlay
	if not overlay or not overlay:IsShown() then
		return
	end

	local config = getTrainerImagePreviewConfig(self.trainerImagePreviewKind, self.selectedTrainer)
	overlay:SetScript("OnUpdate", nil)
	self:ResizeWindow(self:GetTrainerDetailWindowName(self.selectedTrainer), immediate)

	if immediate then
		overlay:Hide()
		overlay:SetAlpha(0)
		self.trainerImagePreviewImage:SetTexture(nil)
		self.trainerImagePreviewKind = nil
		self.trainerImagePreviewProgress = nil
		return
	end

	local elapsedTime = 0
	local startAmount = self.trainerImagePreviewProgress or 1
	overlay:SetScript("OnUpdate", function(activeOverlay, elapsed)
		elapsedTime = elapsedTime + elapsed
		local progress = math.min(elapsedTime / TRAINER_DETAIL_PREVIEW_DURATION, 1)
		self:SetTrainerImagePreviewProgress(config, startAmount * (1 - easeOutCubic(progress)))

		if progress >= 1 then
			activeOverlay:SetScript("OnUpdate", nil)
			activeOverlay:Hide()
			activeOverlay:SetAlpha(0)
			self.trainerImagePreviewImage:SetTexture(nil)
			self.trainerImagePreviewKind = nil
			self.trainerImagePreviewProgress = nil
		end
	end)
end

function ProfessionMenu:RefreshTrainerDetail()
	local trainer = self.selectedTrainer
	if not trainer then
		return
	end

	local hasMedia = trainer.modelImage or trainer.mapImage

	self.trainerDetailHeaderTitle:SetText(trainer.name)
	self.trainerDetailHeaderSubtitle:SetText(trainer.title or "Trainer")
	setTrainerImage(self.trainerDetailImage, trainer, 86, 80, 42)
	self.trainerDetailName:SetText(trainer.name)
	self.trainerDetailRole:SetText(trainer.title or "Trainer")
	self.trainerDetailLocation:SetText(getTrainerLocationText(trainer, true))
	self.trainerDetailNpcID:SetText("NPC ID: " .. tostring(trainer.npcID or ""))

	if hasMedia then
		self.trainerDetailPanel:SetSize(TRAINER_DETAIL_PANEL_WIDTH, TRAINER_DETAIL_MEDIA_PANEL_HEIGHT)
		self.trainerDetailLocationLabel:ClearAllPoints()
		self.trainerDetailLocationLabel:SetPoint("TOPLEFT", self.trainerDetailPanel, "TOPLEFT", 20, -196)
		self.trainerDetailLocation:SetWidth(TRAINER_DETAIL_MAP_WIDTH)
		self.trainerDetailLocation:ClearAllPoints()
		self.trainerDetailLocation:SetPoint("TOPLEFT", self.trainerDetailLocationLabel, "BOTTOMLEFT", 0, -5)
		self.trainerDetailWaypointButton:ClearAllPoints()
		self.trainerDetailWaypointButton:SetPoint("TOPRIGHT", self.trainerDetailMapFrame, "TOPRIGHT", 0, 31)
		self.trainerDetailMapFrame:ClearAllPoints()
		self.trainerDetailMapFrame:SetPoint("TOPLEFT", self.trainerDetailLocation, "BOTTOMLEFT", 0, -12)
	else
		self.trainerDetailPanel:SetSize(TRAINER_DETAIL_PANEL_WIDTH, TRAINER_DETAIL_PANEL_HEIGHT)
		self.trainerDetailLocationLabel:ClearAllPoints()
		self.trainerDetailLocationLabel:SetPoint("TOPLEFT", self.trainerDetailImageFrame, "BOTTOMLEFT", 0, -18)
		self.trainerDetailLocation:SetWidth(318)
		self.trainerDetailLocation:ClearAllPoints()
		self.trainerDetailLocation:SetPoint("TOPLEFT", self.trainerDetailLocationLabel, "BOTTOMLEFT", 0, -5)
		self.trainerDetailWaypointButton:Hide()
		self.trainerDetailMapFrame:Hide()
	end

	local hasModel, modelWidth, modelHeight = setTrainerDetailImage(self.trainerDetailModel, trainer.modelImage, trainer.modelImageSize, TRAINER_DETAIL_MODEL_WIDTH, TRAINER_DETAIL_MODEL_HEIGHT)
	if hasModel then
		self.trainerDetailModelButton:ClearAllPoints()
		self.trainerDetailModelButton:SetPoint("CENTER", self.trainerDetailModelFrame, "CENTER", 0, 0)
		self.trainerDetailModelButton:SetSize(modelWidth, modelHeight)
		self.trainerDetailModelHint:Hide()
		self.trainerDetailModelButton:Show()
		self.trainerDetailNpcID:ClearAllPoints()
		self.trainerDetailNpcID:SetPoint("TOP", self.trainerDetailModelFrame, "BOTTOM", 0, -8)
		self.trainerDetailNpcID:SetWidth(140)
		self.trainerDetailNpcID:SetJustifyH("CENTER")
	else
		self.trainerDetailModelHint:Hide()
		self.trainerDetailModelButton:Hide()
		self.trainerDetailNpcID:ClearAllPoints()
		self.trainerDetailNpcID:SetPoint("TOPLEFT", self.trainerDetailLocation, "BOTTOMLEFT", 0, -8)
		self.trainerDetailNpcID:SetWidth(318)
		self.trainerDetailNpcID:SetJustifyH("LEFT")
	end

	local hasMap, mapWidth, mapHeight = setTrainerDetailImage(self.trainerDetailMap, trainer.mapImage, trainer.mapImageSize, TRAINER_DETAIL_MAP_WIDTH, TRAINER_DETAIL_MAP_HEIGHT)
	if hasMap then
		self.trainerDetailMapFrame:Show()
		self.trainerDetailMapButton:ClearAllPoints()
		self.trainerDetailMapButton:SetPoint("CENTER", self.trainerDetailMapFrame, "CENTER", 0, 0)
		self.trainerDetailMapButton:SetSize(mapWidth, mapHeight)
		self.trainerDetailMapHint:Hide()
		self.trainerDetailMapButton:Show()
		self.trainerDetailWaypointButton:Show()
	else
		self.trainerDetailMapHint:Hide()
		self.trainerDetailMapFrame:Hide()
		self.trainerDetailMapButton:Hide()
		self.trainerDetailWaypointButton:Hide()
	end
end

ProfessionMenu:RegisterCategoryInitializer(function(menu)
	menu:CreateTrainerMenuView()
	menu:CreateTrainerDetailView()
end)

ProfessionMenu:RegisterSectionHandler("trainers", function(menu)
	menu:GoToTrainerMenu()
end)
