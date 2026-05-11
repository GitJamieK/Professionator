local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_ROW_HEIGHT = C.TRAINER_ROW_HEIGHT
local TRAINER_ROW_GAP = C.TRAINER_ROW_GAP
local TRAINER_IMAGE_WIDTH = C.TRAINER_IMAGE_WIDTH
local TRAINER_IMAGE_HEIGHT = C.TRAINER_IMAGE_HEIGHT
local TRAINER_LIST_HEIGHT = C.TRAINER_LIST_HEIGHT
local GOLD = Shared.Colors.GOLD
local colorTexture = Shared.ColorTexture
local getTrainerLocationText = Trainers.GetTrainerLocationText
local setTrainerImage = Trainers.SetTrainerImage

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
