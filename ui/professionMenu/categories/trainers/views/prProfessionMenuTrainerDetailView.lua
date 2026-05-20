local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_DETAIL_PANEL_WIDTH = C.TRAINER_DETAIL_PANEL_WIDTH
local TRAINER_DETAIL_PANEL_HEIGHT = C.TRAINER_DETAIL_PANEL_HEIGHT
local TRAINER_DETAIL_MODEL_WIDTH = C.TRAINER_DETAIL_MODEL_WIDTH
local TRAINER_DETAIL_MODEL_HEIGHT = C.TRAINER_DETAIL_MODEL_HEIGHT
local TRAINER_DETAIL_MAP_WIDTH = C.TRAINER_DETAIL_MAP_WIDTH
local TRAINER_DETAIL_MAP_HEIGHT = C.TRAINER_DETAIL_MAP_HEIGHT
local TRAINER_DETAIL_PREVIEW_PADDING = C.TRAINER_DETAIL_PREVIEW_PADDING
local SCREEN_PADDING_X = Shared.SCREEN_PADDING_X
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD = Shared.Colors.GOLD
local GOLD_SOFT = Shared.Colors.GOLD_SOFT
local TEXT = Shared.Colors.TEXT
local TEXT_DIM = Shared.Colors.TEXT_DIM
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local createView = Shared.CreateView
local createTrainerImageHoverHint = Trainers.CreateTrainerImageHoverHint

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

	local teachesButton = self:CreateTrainerTeachesButton(panel)
	teachesButton:SetPoint("TOPLEFT", imageFrame, "BOTTOMLEFT", 0, -24)
	teachesButton:Hide()

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
	waypointButton.label = waypointLabel

	waypointButton:SetScript("OnClick", function()
		if not self.selectedTrainer then
			return
		end
		ns.Waypoint:Toggle(self.selectedTrainer, self.selectedProfession and self.selectedProfession.id, self.selectedTrainerFactionID)
	end)
	waypointButton:SetScript("OnEnter", function(button)
		button.hovered = true
		self:SetWaypointButtonState(ns.Waypoint:IsActiveFor(self.selectedTrainer), true)
	end)
	waypointButton:SetScript("OnLeave", function(button)
		button.hovered = false
		self:SetWaypointButtonState(ns.Waypoint:IsActiveFor(self.selectedTrainer), false)
	end)

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
	self.trainerDetailTeachesButton = teachesButton
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
