local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_TEACH_ROW_COLLAPSED_HEIGHT = C.TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
local TRAINER_TEACH_ROW_EXPANDED_HEIGHT = C.TRAINER_TEACH_ROW_EXPANDED_HEIGHT
local TRAINER_TEACH_ROW_GAP = C.TRAINER_TEACH_ROW_GAP
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD = Shared.Colors.GOLD
local TEXT = Shared.Colors.TEXT
local TEXT_DIM = Shared.Colors.TEXT_DIM
local BORDER_BRIGHT = Shared.Colors.BORDER_BRIGHT
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local clamp = Trainers.Clamp

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

function ProfessionMenu:SetWaypointButtonState(active, hovered)
	local button = self.trainerDetailWaypointButton
	if not button then
		return
	end

	local faction = self:GetTrainerFaction(self.selectedTrainerFactionID)
	local accent = (faction and faction.accent) or GOLD

	if active then
		applyBackdrop(button, BUTTON_BACKDROP, { accent[1] * 0.22, accent[2] * 0.22, accent[3] * 0.22, 0.95 }, { accent[1], accent[2], accent[3], 1 })
		if button.label then
			button.label:SetTextColor(1, 0.93, 0.66, 1)
		end
	else
		local borderColor = hovered and BORDER_BRIGHT or { 0.30, 0.30, 0.31, 1 }
		applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, hovered and 0.96 or 0.90 }, borderColor)
		if button.label then
			setTextColor(button.label, hovered and TEXT or TEXT_DIM)
		end
	end
end

function ProfessionMenu:RefreshWaypointButton()
	local button = self.trainerDetailWaypointButton
	if button and button:IsShown() then
		self:SetWaypointButtonState(ns.Waypoint:IsActiveFor(self.selectedTrainer), button.hovered)
	end
end

function ProfessionMenu:SetTrainerTeachRowState(row, selected, hovered)
	local faction = self:GetTrainerFaction(self.selectedTrainerFactionID)
	local accent = (faction and faction.accent) or GOLD
	local borderColor = selected and { accent[1], accent[2], accent[3], 0.96 } or (hovered and BORDER_BRIGHT or { 0.22, 0.22, 0.23, 1 })

	applyBackdrop(row, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, selected and 0.96 or 0.90 }, borderColor)
	row.highlight:SetAlpha(selected and 0.42 or (hovered and 0.22 or 0))
	row.chevron:SetText(selected and "-" or "+")
	row.chevron:SetTextColor(selected and 0.95 or 0.56, selected and 0.83 or 0.53, selected and 0.44 or 0.46, 1)

	if selected or hovered then
		row.name:SetTextColor(1, 0.93, 0.66, 1)
		row.line1:SetTextColor(0.96, 0.92, 0.82, 1)
	else
		setTextColor(row.name, GOLD)
		setTextColor(row.line1, TEXT)
	end
end

function ProfessionMenu:GetTrainerTeachRowTargetHeight(row)
	if row and row.index == self.selectedTrainerTeachIndex then
		return TRAINER_TEACH_ROW_EXPANDED_HEIGHT
	end

	return TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
end

function ProfessionMenu:ApplyTrainerTeachLayout()
	if not self.trainerTeachList then
		return
	end

	local offset = 0
	local visibleRows = 0
	for _, row in ipairs(self.trainerTeachRows) do
		if row:IsShown() then
			local selected = row.index == self.selectedTrainerTeachIndex
			local height = row.currentHeight or self:GetTrainerTeachRowTargetHeight(row)
			local expandProgress = clamp((height - TRAINER_TEACH_ROW_COLLAPSED_HEIGHT) / (TRAINER_TEACH_ROW_EXPANDED_HEIGHT - TRAINER_TEACH_ROW_COLLAPSED_HEIGHT), 0, 1)

			row:SetHeight(height)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", self.trainerTeachList, "TOPLEFT", 0, -offset)
			row.detail:SetAlpha(expandProgress)
			row.divider:SetAlpha(expandProgress)
			if expandProgress > 0.02 then
				row.detail:Show()
				row.divider:Show()
			else
				row.detail:Hide()
				row.divider:Hide()
			end

			self:SetTrainerTeachRowState(row, selected, row.hovered)
			offset = offset + height + TRAINER_TEACH_ROW_GAP
			visibleRows = visibleRows + 1
		end
	end

	if visibleRows > 0 then
		offset = offset - TRAINER_TEACH_ROW_GAP
	end
	self.trainerTeachList:SetHeight(math.max(offset, 1))
	self:RefreshTrainerTeachScrollBounds(offset)
end
