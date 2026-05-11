local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local TEXT = Shared.Colors.TEXT
local BORDER_BRIGHT = Shared.Colors.BORDER_BRIGHT
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local easeOutCubic = Shared.EaseOutCubic
local TRAINER_FACTIONS = Trainers.Factions

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
