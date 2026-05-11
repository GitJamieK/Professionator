local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_ROW_HEIGHT = C.TRAINER_ROW_HEIGHT
local TRAINER_LIST_HEIGHT = C.TRAINER_LIST_HEIGHT
local TRAINER_SCROLL_THUMB_MIN_HEIGHT = C.TRAINER_SCROLL_THUMB_MIN_HEIGHT
local TRAINER_SCROLL_STEP = C.TRAINER_SCROLL_STEP
local TRAINER_SCROLL_SMOOTHING = C.TRAINER_SCROLL_SMOOTHING
local clamp = Trainers.Clamp

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

function ProfessionMenu:GetTrainerScrollCursorOffset(track)
	if not track then
		return nil
	end

	local _, cursorY = GetCursorPosition()
	local scale = track:GetEffectiveScale() or 1
	local top = track:GetTop()
	if not cursorY or not top then
		return nil
	end

	return top - (cursorY / scale)
end

function ProfessionMenu:GetTrainerScrollGeometry(track)
	if not track then
		return nil
	end

	local height = track:GetHeight() or TRAINER_LIST_HEIGHT
	if height <= 0 then
		return nil
	end

	local maxScroll = self.trainerScrollMax or 0
	local thumbHeight = self.trainerScrollThumb and (self.trainerScrollThumb:GetHeight() or TRAINER_SCROLL_THUMB_MIN_HEIGHT) or TRAINER_SCROLL_THUMB_MIN_HEIGHT
	local travel = math.max(height - thumbHeight, 1)
	local current = self.trainerScrollFrame and (self.trainerScrollFrame:GetVerticalScroll() or 0) or 0
	local thumbOffset = maxScroll > 0 and (current / maxScroll) * travel or 0

	return height, thumbHeight, travel, thumbOffset
end

function ProfessionMenu:HandleTrainerScrollTrackMouseDown(track)
	if not track or (self.trainerScrollMax or 0) <= 0 then
		return
	end

	local cursorOffset = self:GetTrainerScrollCursorOffset(track)
	local _, thumbHeight, _, thumbOffset = self:GetTrainerScrollGeometry(track)
	if not cursorOffset or not thumbHeight or not thumbOffset then
		return
	end

	if cursorOffset >= thumbOffset and cursorOffset <= (thumbOffset + thumbHeight) then
		self:StartTrainerScrollDrag(track, cursorOffset - thumbOffset)
		return
	end

	self:PageTrainerScrollFromTrackClick(cursorOffset, thumbOffset, thumbHeight)
end

function ProfessionMenu:PageTrainerScrollFromTrackClick(cursorOffset, thumbOffset, thumbHeight)
	if not cursorOffset or not thumbOffset or not thumbHeight then
		return
	end

	local current = (self.trainerScrollFrame and (self.trainerScrollFrame:GetVerticalScroll() or 0)) or self.trainerScrollTarget or 0
	local pageAmount = math.max(TRAINER_SCROLL_STEP, TRAINER_LIST_HEIGHT - TRAINER_ROW_HEIGHT)
	if cursorOffset < thumbOffset then
		self:SetTrainerScrollTarget(current - pageAmount)
	elseif cursorOffset > (thumbOffset + thumbHeight) then
		self:SetTrainerScrollTarget(current + pageAmount)
	end
end

function ProfessionMenu:StartTrainerScrollDrag(track, gripOffset)
	if not track or (self.trainerScrollMax or 0) <= 0 then
		return
	end

	self.trainerDraggingScroll = true
	self.trainerScrollDragGripOffset = gripOffset or (self.trainerScrollThumb and ((self.trainerScrollThumb:GetHeight() or TRAINER_SCROLL_THUMB_MIN_HEIGHT) / 2)) or (TRAINER_SCROLL_THUMB_MIN_HEIGHT / 2)
	if self.trainerScrollAnimator then
		self.trainerScrollAnimator:SetScript("OnUpdate", nil)
		self.trainerScrollAnimator:Hide()
	end

	track:SetScript("OnUpdate", function(activeTrack)
		if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
			self:StopTrainerScrollDrag()
			return
		end

		self:UpdateTrainerScrollFromCursor(activeTrack)
	end)
	self:UpdateTrainerScrollFromCursor(track)
end

function ProfessionMenu:StopTrainerScrollDrag()
	self.trainerDraggingScroll = false
	self.trainerScrollDragGripOffset = nil
	if self.trainerScrollTrack then
		self.trainerScrollTrack:SetScript("OnUpdate", nil)
	end
end

function ProfessionMenu:UpdateTrainerScrollFromCursor(track)
	if not track or not self.trainerScrollFrame then
		return
	end

	local cursorOffset = self:GetTrainerScrollCursorOffset(track)
	local _, thumbHeight, travel = self:GetTrainerScrollGeometry(track)
	if not cursorOffset or not thumbHeight or not travel then
		return
	end

	local gripOffset = clamp(self.trainerScrollDragGripOffset or (thumbHeight / 2), 0, thumbHeight)
	local offset = clamp(cursorOffset - gripOffset, 0, travel)
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
