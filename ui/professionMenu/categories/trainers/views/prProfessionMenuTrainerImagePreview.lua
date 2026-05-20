local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_DETAIL_PANEL_WIDTH = C.TRAINER_DETAIL_PANEL_WIDTH
local TRAINER_DETAIL_PANEL_HEIGHT = C.TRAINER_DETAIL_PANEL_HEIGHT
local TRAINER_DETAIL_MEDIA_PANEL_HEIGHT = C.TRAINER_DETAIL_MEDIA_PANEL_HEIGHT
local TRAINER_DETAIL_MODEL_WIDTH = C.TRAINER_DETAIL_MODEL_WIDTH
local TRAINER_DETAIL_MODEL_HEIGHT = C.TRAINER_DETAIL_MODEL_HEIGHT
local TRAINER_DETAIL_MAP_WIDTH = C.TRAINER_DETAIL_MAP_WIDTH
local TRAINER_DETAIL_MAP_HEIGHT = C.TRAINER_DETAIL_MAP_HEIGHT
local TRAINER_DETAIL_PREVIEW_DURATION = C.TRAINER_DETAIL_PREVIEW_DURATION
local easeOutCubic = Shared.EaseOutCubic
local getTrainerLocationText = Trainers.GetTrainerLocationText
local setTrainerImage = Trainers.SetTrainerImage
local setTrainerDetailImage = Trainers.SetTrainerDetailImage
local getTrainerImagePreviewConfig = Trainers.GetTrainerImagePreviewConfig
local hasTrainerTeaches = Trainers.HasTrainerTeaches

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
	local hasTeaches = hasTrainerTeaches(trainer)

	self.trainerDetailHeaderTitle:SetText(trainer.name)
	self.trainerDetailHeaderSubtitle:SetText(trainer.title or "Trainer")
	setTrainerImage(self.trainerDetailImage, trainer, 86, 80, 42)
	self.trainerDetailName:SetText(trainer.name)
	self.trainerDetailRole:SetText(trainer.title or "Trainer")
	self.trainerDetailLocation:SetText(getTrainerLocationText(trainer, true))
	self.trainerDetailNpcID:SetText("NPC ID: " .. tostring(trainer.npcID or ""))

	if self.trainerDetailTeachesButton then
		if hasTeaches then
			self.trainerDetailTeachesButton:Show()
		else
			self.trainerDetailTeachesButton:Hide()
		end
	end

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
		self.trainerDetailLocationLabel:SetPoint("TOPLEFT", self.trainerDetailImageFrame, "BOTTOMLEFT", 0, hasTeaches and -56 or -18)
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
		self:SetWaypointButtonState(ns.Waypoint:IsActiveFor(trainer), self.trainerDetailWaypointButton.hovered)
	else
		self.trainerDetailMapHint:Hide()
		self.trainerDetailMapFrame:Hide()
		self.trainerDetailMapButton:Hide()
		self.trainerDetailWaypointButton:Hide()
	end
end
