local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_SCROLL_TRACK_WIDTH = C.TRAINER_SCROLL_TRACK_WIDTH
local TRAINER_SCROLL_STEP = C.TRAINER_SCROLL_STEP
local TRAINER_TEACHES_PANEL_WIDTH = C.TRAINER_TEACHES_PANEL_WIDTH
local TRAINER_TEACHES_PANEL_HEIGHT = C.TRAINER_TEACHES_PANEL_HEIGHT
local TRAINER_TEACH_ROW_WIDTH = C.TRAINER_TEACH_ROW_WIDTH
local TRAINER_TEACH_LIST_HEIGHT = C.TRAINER_TEACH_LIST_HEIGHT
local SCREEN_PADDING_X = Shared.SCREEN_PADDING_X
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local TEXT_DIM = Shared.Colors.TEXT_DIM
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local createView = Shared.CreateView

function ProfessionMenu:CreateTrainerTeachesView()
	local view = createView(self.stage, "TrainerTeachesView")
	self.views.trainerTeaches = view

	local title, subtitle = self:CreateHeader(view, "Teaches", "Trainer", function()
		self:GoBackToTrainerDetail()
	end)
	self.trainerTeachesHeaderTitle = title
	self.trainerTeachesHeaderSubtitle = subtitle

	local panel = CreateFrame("Frame", nil, view, ns:GetBackdropTemplate())
	panel:SetSize(TRAINER_TEACHES_PANEL_WIDTH, TRAINER_TEACHES_PANEL_HEIGHT)
	panel:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_PADDING_X, -78)
	applyBackdrop(panel, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.82 }, { 0.22, 0.22, 0.23, 1 })

	local summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	summary:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -18)
	summary:SetWidth(TRAINER_TEACH_ROW_WIDTH)
	summary:SetJustifyH("LEFT")
	setTextColor(summary, TEXT_DIM)

	local scrollFrame = CreateFrame("ScrollFrame", nil, panel)
	scrollFrame:SetSize(TRAINER_TEACH_ROW_WIDTH, TRAINER_TEACH_LIST_HEIGHT)
	scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -56)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(frame, delta)
		self:SetTrainerTeachScrollTarget((self.trainerTeachScrollTarget or frame:GetVerticalScroll() or 0) - (delta * TRAINER_SCROLL_STEP))
	end)

	local list = CreateFrame("Frame", nil, scrollFrame)
	list:SetSize(TRAINER_TEACH_ROW_WIDTH, TRAINER_TEACH_LIST_HEIGHT)
	scrollFrame:SetScrollChild(list)

	local scrollTrack = CreateFrame("Frame", nil, panel)
	scrollTrack:SetSize(TRAINER_SCROLL_TRACK_WIDTH, TRAINER_TEACH_LIST_HEIGHT)
	scrollTrack:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 8, 0)
	scrollTrack:EnableMouse(true)
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

		self:HandleTrainerTeachScrollTrackMouseDown(track)
	end)
	scrollTrack:SetScript("OnMouseUp", function()
		self:StopTrainerTeachScrollDrag()
	end)

	local animator = CreateFrame("Frame", nil, view)
	animator:Hide()

	local scrollAnimator = CreateFrame("Frame", nil, view)
	scrollAnimator:Hide()

	local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -56)
	empty:SetWidth(TRAINER_TEACH_ROW_WIDTH)
	empty:SetJustifyH("LEFT")
	empty:SetText("No trainer teachings recorded yet.")
	setTextColor(empty, TEXT_DIM)
	empty:Hide()

	self.trainerTeachesPanel = panel
	self.trainerTeachesSummary = summary
	self.trainerTeachRows = {}
	self.trainerTeachScrollFrame = scrollFrame
	self.trainerTeachList = list
	self.trainerTeachScrollTrack = scrollTrack
	self.trainerTeachScrollThumb = scrollThumb
	self.trainerTeachScrollAnimator = scrollAnimator
	self.trainerTeachScrollTarget = 0
	self.trainerTeachScrollMax = 0
	self.trainerTeachDraggingScroll = false
	self.trainerTeachAnimator = animator
	self.trainerTeachesEmpty = empty
end
