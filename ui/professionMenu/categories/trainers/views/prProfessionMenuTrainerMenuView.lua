local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local FACTION_BUTTON_WIDTH = C.FACTION_BUTTON_WIDTH
local FACTION_BUTTON_HEIGHT = C.FACTION_BUTTON_HEIGHT
local FACTION_BUTTON_GAP = C.FACTION_BUTTON_GAP
local TRAINER_ROW_WIDTH = C.TRAINER_ROW_WIDTH
local TRAINER_ROW_HEIGHT = C.TRAINER_ROW_HEIGHT
local TRAINER_IMAGE_WIDTH = C.TRAINER_IMAGE_WIDTH
local TRAINER_IMAGE_HEIGHT = C.TRAINER_IMAGE_HEIGHT
local TRAINER_LIST_HEIGHT = C.TRAINER_LIST_HEIGHT
local TRAINER_SCROLL_GAP = C.TRAINER_SCROLL_GAP
local TRAINER_SCROLL_TRACK_WIDTH = C.TRAINER_SCROLL_TRACK_WIDTH
local TRAINER_SCROLL_STEP = C.TRAINER_SCROLL_STEP
local SCREEN_PADDING_X = Shared.SCREEN_PADDING_X
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD = Shared.Colors.GOLD
local TEXT = Shared.Colors.TEXT
local TEXT_DIM = Shared.Colors.TEXT_DIM
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local setIcon = Shared.SetIcon
local setTextureCoordinates = Shared.SetTextureCoordinates
local createBody = Shared.CreateBody
local setBodyOffset = Shared.SetBodyOffset
local createTint = Shared.CreateTint
local createView = Shared.CreateView
local TRAINER_FACTIONS = Trainers.Factions

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

		self:HandleTrainerScrollTrackMouseDown(track)
	end)
	scrollTrack:SetScript("OnMouseUp", function()
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
