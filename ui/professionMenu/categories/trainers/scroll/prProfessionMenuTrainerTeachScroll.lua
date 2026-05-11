local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_SCROLL_THUMB_MIN_HEIGHT = C.TRAINER_SCROLL_THUMB_MIN_HEIGHT
local TRAINER_SCROLL_STEP = C.TRAINER_SCROLL_STEP
local TRAINER_SCROLL_SMOOTHING = C.TRAINER_SCROLL_SMOOTHING
local TRAINER_TEACH_ROW_COLLAPSED_HEIGHT = C.TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
local TRAINER_TEACH_LIST_HEIGHT = C.TRAINER_TEACH_LIST_HEIGHT
local TRAINER_TEACH_ANIMATION_DURATION = C.TRAINER_TEACH_ANIMATION_DURATION
local easeOutCubic = Shared.EaseOutCubic
local clamp = Trainers.Clamp

function ProfessionMenu:RefreshTrainerTeachScrollBounds(contentHeight)
	if not self.trainerTeachScrollFrame then
		return
	end

	self.trainerTeachScrollMax = math.max((contentHeight or 0) - TRAINER_TEACH_LIST_HEIGHT, 0)
	if self.trainerTeachScrollFrame.UpdateScrollChildRect then
		self.trainerTeachScrollFrame:UpdateScrollChildRect()
	end

	if (self.trainerTeachScrollTarget or 0) > self.trainerTeachScrollMax then
		self:SetTrainerTeachScrollTarget(self.trainerTeachScrollMax, true)
		return
	end

	if self.trainerTeachScrollMax <= 0 then
		self:SetTrainerTeachScrollTarget(0, true)
		return
	end

	self:RefreshTrainerTeachScrollIndicator()
end

function ProfessionMenu:SetTrainerTeachScrollTarget(target, immediate)
	if not self.trainerTeachScrollFrame then
		return
	end

	self.trainerTeachScrollTarget = clamp(target or 0, 0, self.trainerTeachScrollMax or 0)
	if immediate then
		self.trainerTeachScrollFrame:SetVerticalScroll(self.trainerTeachScrollTarget)
		self:RefreshTrainerTeachScrollIndicator()
		return
	end

	self:StartTrainerTeachSmoothScroll()
end

function ProfessionMenu:StartTrainerTeachSmoothScroll()
	if not self.trainerTeachScrollAnimator then
		return
	end

	self.trainerTeachScrollAnimator:SetScript("OnUpdate", function(_, elapsed)
		self:UpdateTrainerTeachSmoothScroll(elapsed)
	end)
	self.trainerTeachScrollAnimator:Show()
end

function ProfessionMenu:UpdateTrainerTeachSmoothScroll(elapsed)
	if not self.trainerTeachScrollFrame then
		return
	end

	local current = self.trainerTeachScrollFrame:GetVerticalScroll() or 0
	local target = self.trainerTeachScrollTarget or 0
	local progress = math.min(elapsed * TRAINER_SCROLL_SMOOTHING, 1)
	local nextScroll = current + ((target - current) * progress)

	if math.abs(target - nextScroll) < 0.5 then
		nextScroll = target
		if self.trainerTeachScrollAnimator then
			self.trainerTeachScrollAnimator:SetScript("OnUpdate", nil)
			self.trainerTeachScrollAnimator:Hide()
		end
	end

	self.trainerTeachScrollFrame:SetVerticalScroll(nextScroll)
	self:RefreshTrainerTeachScrollIndicator()
end

function ProfessionMenu:GetTrainerTeachScrollGeometry(track)
	if not track then
		return nil
	end

	local height = track:GetHeight() or TRAINER_TEACH_LIST_HEIGHT
	if height <= 0 then
		return nil
	end

	local maxScroll = self.trainerTeachScrollMax or 0
	local thumbHeight = self.trainerTeachScrollThumb and (self.trainerTeachScrollThumb:GetHeight() or TRAINER_SCROLL_THUMB_MIN_HEIGHT) or TRAINER_SCROLL_THUMB_MIN_HEIGHT
	local travel = math.max(height - thumbHeight, 1)
	local current = self.trainerTeachScrollFrame and (self.trainerTeachScrollFrame:GetVerticalScroll() or 0) or 0
	local thumbOffset = maxScroll > 0 and (current / maxScroll) * travel or 0

	return height, thumbHeight, travel, thumbOffset
end

function ProfessionMenu:HandleTrainerTeachScrollTrackMouseDown(track)
	if not track or (self.trainerTeachScrollMax or 0) <= 0 then
		return
	end

	local cursorOffset = self:GetTrainerScrollCursorOffset(track)
	local _, thumbHeight, _, thumbOffset = self:GetTrainerTeachScrollGeometry(track)
	if not cursorOffset or not thumbHeight or not thumbOffset then
		return
	end

	if cursorOffset >= thumbOffset and cursorOffset <= (thumbOffset + thumbHeight) then
		self:StartTrainerTeachScrollDrag(track, cursorOffset - thumbOffset)
		return
	end

	self:PageTrainerTeachScrollFromTrackClick(cursorOffset, thumbOffset, thumbHeight)
end

function ProfessionMenu:PageTrainerTeachScrollFromTrackClick(cursorOffset, thumbOffset, thumbHeight)
	if not cursorOffset or not thumbOffset or not thumbHeight then
		return
	end

	local current = (self.trainerTeachScrollFrame and (self.trainerTeachScrollFrame:GetVerticalScroll() or 0)) or self.trainerTeachScrollTarget or 0
	local pageAmount = math.max(TRAINER_SCROLL_STEP, TRAINER_TEACH_LIST_HEIGHT - TRAINER_TEACH_ROW_COLLAPSED_HEIGHT)
	if cursorOffset < thumbOffset then
		self:SetTrainerTeachScrollTarget(current - pageAmount)
	elseif cursorOffset > (thumbOffset + thumbHeight) then
		self:SetTrainerTeachScrollTarget(current + pageAmount)
	end
end

function ProfessionMenu:StartTrainerTeachScrollDrag(track, gripOffset)
	if not track or (self.trainerTeachScrollMax or 0) <= 0 then
		return
	end

	self.trainerTeachDraggingScroll = true
	self.trainerTeachScrollDragGripOffset = gripOffset or (self.trainerTeachScrollThumb and ((self.trainerTeachScrollThumb:GetHeight() or TRAINER_SCROLL_THUMB_MIN_HEIGHT) / 2)) or (TRAINER_SCROLL_THUMB_MIN_HEIGHT / 2)
	if self.trainerTeachScrollAnimator then
		self.trainerTeachScrollAnimator:SetScript("OnUpdate", nil)
		self.trainerTeachScrollAnimator:Hide()
	end

	track:SetScript("OnUpdate", function(activeTrack)
		if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
			self:StopTrainerTeachScrollDrag()
			return
		end

		self:UpdateTrainerTeachScrollFromCursor(activeTrack)
	end)
	self:UpdateTrainerTeachScrollFromCursor(track)
end

function ProfessionMenu:StopTrainerTeachScrollDrag()
	self.trainerTeachDraggingScroll = false
	self.trainerTeachScrollDragGripOffset = nil
	if self.trainerTeachScrollTrack then
		self.trainerTeachScrollTrack:SetScript("OnUpdate", nil)
	end
end

function ProfessionMenu:UpdateTrainerTeachScrollFromCursor(track)
	if not track or not self.trainerTeachScrollFrame then
		return
	end

	local cursorOffset = self:GetTrainerScrollCursorOffset(track)
	local _, thumbHeight, travel = self:GetTrainerTeachScrollGeometry(track)
	if not cursorOffset or not thumbHeight or not travel then
		return
	end

	local gripOffset = clamp(self.trainerTeachScrollDragGripOffset or (thumbHeight / 2), 0, thumbHeight)
	local offset = clamp(cursorOffset - gripOffset, 0, travel)
	local target = (offset / travel) * (self.trainerTeachScrollMax or 0)

	self:SetTrainerTeachScrollTarget(target, true)
end

function ProfessionMenu:RefreshTrainerTeachScrollIndicator()
	if not self.trainerTeachScrollTrack or not self.trainerTeachScrollThumb then
		return
	end

	local maxScroll = self.trainerTeachScrollMax or 0
	if maxScroll <= 0 then
		self.trainerTeachScrollTrack:Hide()
		return
	end

	local contentHeight = maxScroll + TRAINER_TEACH_LIST_HEIGHT
	local thumbHeight = math.max(TRAINER_SCROLL_THUMB_MIN_HEIGHT, TRAINER_TEACH_LIST_HEIGHT * (TRAINER_TEACH_LIST_HEIGHT / contentHeight))
	local current = self.trainerTeachScrollFrame and (self.trainerTeachScrollFrame:GetVerticalScroll() or 0) or 0
	local travel = TRAINER_TEACH_LIST_HEIGHT - thumbHeight
	local offset = maxScroll > 0 and (current / maxScroll) * travel or 0

	self.trainerTeachScrollThumb:SetHeight(thumbHeight)
	self.trainerTeachScrollThumb:ClearAllPoints()
	self.trainerTeachScrollThumb:SetPoint("TOP", self.trainerTeachScrollTrack, "TOP", 0, -offset)
	self.trainerTeachScrollTrack:Show()
end

function ProfessionMenu:RefreshTrainerTeachLayout(immediate)
	if immediate then
		if self.trainerTeachAnimator then
			self.trainerTeachAnimator:SetScript("OnUpdate", nil)
			self.trainerTeachAnimator:Hide()
		end

		for _, row in ipairs(self.trainerTeachRows) do
			if row:IsShown() then
				row.currentHeight = self:GetTrainerTeachRowTargetHeight(row)
			end
		end
		self:ApplyTrainerTeachLayout()
		return
	end

	self:StartTrainerTeachLayoutAnimation()
end

function ProfessionMenu:StartTrainerTeachLayoutAnimation()
	if not self.trainerTeachAnimator then
		self:RefreshTrainerTeachLayout(true)
		return
	end

	for _, row in ipairs(self.trainerTeachRows) do
		if row:IsShown() then
			row.startHeight = row.currentHeight or row:GetHeight() or TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
			row.targetHeight = self:GetTrainerTeachRowTargetHeight(row)
			if row.startHeight > TRAINER_TEACH_ROW_COLLAPSED_HEIGHT or row.targetHeight > TRAINER_TEACH_ROW_COLLAPSED_HEIGHT then
				row.detail:Show()
				row.divider:Show()
			end
		end
	end

	local elapsedTime = 0
	self.trainerTeachAnimator:SetScript("OnUpdate", function(animator, elapsed)
		elapsedTime = elapsedTime + elapsed
		local progress = math.min(elapsedTime / TRAINER_TEACH_ANIMATION_DURATION, 1)
		local eased = easeOutCubic(progress)

		for _, row in ipairs(self.trainerTeachRows) do
			if row:IsShown() then
				local startHeight = row.startHeight or TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
				local targetHeight = row.targetHeight or self:GetTrainerTeachRowTargetHeight(row)
				row.currentHeight = startHeight + ((targetHeight - startHeight) * eased)
			end
		end

		self:ApplyTrainerTeachLayout()

		if progress >= 1 then
			animator:SetScript("OnUpdate", nil)
			animator:Hide()
			for _, row in ipairs(self.trainerTeachRows) do
				if row:IsShown() then
					row.currentHeight = row.targetHeight or self:GetTrainerTeachRowTargetHeight(row)
					row.startHeight = nil
					row.targetHeight = nil
				end
			end
			self:ApplyTrainerTeachLayout()
		end
	end)
	self.trainerTeachAnimator:Show()
end
