local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local GOLD = Shared.Colors.GOLD
local colorTexture = Shared.ColorTexture
local setIcon = Shared.SetIcon
local hasTrainerTeaches = Trainers.HasTrainerTeaches
local getTrainerTeachName = Trainers.GetTrainerTeachName
local getTrainerTeachIcon = Trainers.GetTrainerTeachIcon
local getTrainerTeachLines = Trainers.GetTrainerTeachLines

function ProfessionMenu:SelectTrainerTeach(index)
	if not index then
		return
	end

	self.selectedTrainerTeachIndex = index == self.selectedTrainerTeachIndex and nil or index
	self:RefreshTrainerTeachLayout(false)
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

function ProfessionMenu:GoToTrainerTeaches()
	if not hasTrainerTeaches(self.selectedTrainer) then
		return
	end

	self:CloseTrainerImagePreview(true)
	self:RefreshTrainerTeaches()
	self:ResizeWindow("trainerTeaches")
	self:TransitionTo(self.views.trainerTeaches, 1, "trainerTeaches")
end

function ProfessionMenu:GoBackToTrainerDetail()
	if not self.selectedTrainer then
		self:GoBackToTrainerList()
		return
	end

	local targetName = self:GetTrainerDetailWindowName(self.selectedTrainer)
	self:RefreshTrainerDetail()
	self:ResizeWindow(targetName)
	self:TransitionTo(self.views.trainerDetail, -1, targetName)
end

function ProfessionMenu:RefreshTrainerTeaches()
	local trainer = self.selectedTrainer
	local teaches = (trainer and trainer.teaches) or {}
	local faction = self:GetTrainerFaction(self.selectedTrainerFactionID)
	local accent = (faction and faction.accent) or GOLD

	self.trainerTeachesHeaderTitle:SetText(trainer and trainer.name or "Teaches")
	self.trainerTeachesHeaderSubtitle:SetText("What this trainer teaches")
	self.trainerTeachesSummary:SetText(tostring(#teaches) .. " entries")
	local trainerChanged = self.selectedTrainerTeachTrainer ~= trainer
	if trainerChanged then
		self.selectedTrainerTeachTrainer = trainer
		self.selectedTrainerTeachIndex = #teaches > 0 and 1 or nil
	elseif self.selectedTrainerTeachIndex and self.selectedTrainerTeachIndex > #teaches then
		self.selectedTrainerTeachIndex = nil
	end

	if #teaches == 0 then
		self.trainerTeachesEmpty:Show()
	else
		self.trainerTeachesEmpty:Hide()
	end

	for index, teach in ipairs(teaches) do
		local row = self.trainerTeachRows[index]
		if not row then
			row = self:CreateTrainerTeachRow(self.trainerTeachList)
			self.trainerTeachRows[index] = row
		end

		local line1, line2, line3, line4 = getTrainerTeachLines(teach)
		row.index = index
		row.teach = teach
		row:ClearAllPoints()
		colorTexture(row.stripe, accent[1], accent[2], accent[3], 0.84)
		setIcon(row.icon, getTrainerTeachIcon(teach))
		if teach.creates and teach.creates.itemID then
			row.iconButton.itemID = teach.creates.itemID
			row.iconButton.reagentName = teach.creates.name
		else
			row.iconButton.itemID = nil
			row.iconButton.reagentName = nil
		end
		row.name:SetText(getTrainerTeachName(teach))
		row.line1:SetText(line1 or "")
		row.line2:SetText(line2 or "")
		row.line3:SetText(line3 or "")
		row.line4:SetText(line4 or "")
		self:RefreshTrainerTeachReagents(row, teach)
		if line4 and line4 ~= "" then
			row.line4:Show()
		else
			row.line4:Hide()
		end
		row:Show()
	end

	for index = #teaches + 1, #self.trainerTeachRows do
		self.trainerTeachRows[index].index = nil
		self.trainerTeachRows[index].teach = nil
		self.trainerTeachRows[index]:Hide()
	end

	self:RefreshTrainerTeachLayout(true)
	if trainerChanged then
		self:SetTrainerTeachScrollTarget(0, true)
	end
end

function ProfessionMenu:GoBackToTrainerList()
	self:CloseTrainerImagePreview(true)
	self:RefreshTrainerFactions()
	self:RefreshTrainerList()
	self:ResizeWindow(self:GetTrainerListWindowName())
	self:TransitionTo(self.views.trainers, -1, self:GetTrainerListWindowName())
end
