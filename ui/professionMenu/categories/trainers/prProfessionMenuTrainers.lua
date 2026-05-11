local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared

local FACTION_BUTTON_WIDTH = 112
local FACTION_BUTTON_HEIGHT = 32
local FACTION_BUTTON_GAP = 10
local TRAINER_ROW_WIDTH = 470
local TRAINER_ROW_HEIGHT = 78
local TRAINER_ROW_GAP = 8
local TRAINER_IMAGE_WIDTH = 72
local TRAINER_IMAGE_HEIGHT = 66
local TRAINER_LIST_HEIGHT = 300
local TRAINER_DETAIL_PANEL_WIDTH = 492
local TRAINER_DETAIL_PANEL_HEIGHT = 190
local TRAINER_DETAIL_MEDIA_PANEL_HEIGHT = 595
local TRAINER_DETAIL_MODEL_WIDTH = 104
local TRAINER_DETAIL_MODEL_HEIGHT = 148
local TRAINER_DETAIL_MAP_WIDTH = 420
local TRAINER_DETAIL_MAP_HEIGHT = 289
local TRAINER_DETAIL_MODEL_PREVIEW_WIDTH = 300
local TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT = 450
local TRAINER_DETAIL_MAP_PREVIEW_WIDTH = 760
local TRAINER_DETAIL_MAP_PREVIEW_HEIGHT = 524
local TRAINER_DETAIL_PREVIEW_PADDING = 5
local TRAINER_DETAIL_PREVIEW_DURATION = 0.22
local TRAINER_DETAIL_IMAGE_HINT_TEXT = "Click to enlarge"
local TRAINER_DETAIL_IMAGE_HINT_WIDTH = 112
local TRAINER_DETAIL_IMAGE_HINT_HEIGHT = 22
local TRAINER_SCROLL_GAP = 10
local TRAINER_SCROLL_TRACK_WIDTH = 8
local TRAINER_SCROLL_THUMB_MIN_HEIGHT = 36
local TRAINER_SCROLL_STEP = 82
local TRAINER_SCROLL_SMOOTHING = 16
local TRAINER_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Bandage_11"
local TRAINER_TEACHES_BUTTON_WIDTH = 142
local TRAINER_TEACHES_BUTTON_HEIGHT = 26
local TRAINER_TEACHES_PANEL_WIDTH = TRAINER_DETAIL_PANEL_WIDTH
local TRAINER_TEACHES_PANEL_HEIGHT = TRAINER_DETAIL_MEDIA_PANEL_HEIGHT
local TRAINER_TEACH_ROW_WIDTH = 456
local TRAINER_TEACH_ROW_COLLAPSED_HEIGHT = 52
local TRAINER_TEACH_ROW_EXPANDED_HEIGHT = 112
local TRAINER_TEACH_ROW_GAP = 8
local TRAINER_TEACH_ICON_SIZE = 34
local TRAINER_TEACH_LIST_HEIGHT = 530
local TRAINER_TEACH_ANIMATION_DURATION = 0.20
local TRAINER_REAGENT_ICON_SIZE = 22
local TRAINER_REAGENT_ICON_GAP = 5
local SCREEN_PADDING_X = Shared.SCREEN_PADDING_X
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD = Shared.Colors.GOLD
local GOLD_SOFT = Shared.Colors.GOLD_SOFT
local TEXT = Shared.Colors.TEXT
local TEXT_DIM = Shared.Colors.TEXT_DIM
local BORDER_BRIGHT = Shared.Colors.BORDER_BRIGHT
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local easeOutCubic = Shared.EaseOutCubic
local setIcon = Shared.SetIcon
local getSpellTexture = Shared.GetSpellTexture
local setTextureCoordinates = Shared.SetTextureCoordinates
local createBody = Shared.CreateBody
local setBodyOffset = Shared.SetBodyOffset
local createTint = Shared.CreateTint
local createView = Shared.CreateView

Shared.RegisterWindowSize("trainers", 560, 270)
Shared.RegisterWindowSize("trainerList", 560, 500)
Shared.RegisterWindowSize("trainerDetail", 570, 390)
Shared.RegisterWindowSize("trainerDetailMedia", 570, 740)
Shared.RegisterWindowSize("trainerDetailModelPreview", 570, 740)
Shared.RegisterWindowSize("trainerDetailMapPreview", 860, 760)
Shared.RegisterWindowSize("trainerTeaches", 570, 740)

local TRAINER_FACTIONS = {
	{
		id = "horde",
		label = "Horde",
		icon = "Interface\\TargetingFrame\\UI-PVP-Horde",
		iconTexCoord = { 0, 0.59375, 0, 0.5625 },
		accent = { 0.90, 0.18, 0.14 },
	},
	{
		id = "alliance",
		label = "Alliance",
		icon = "Interface\\TargetingFrame\\UI-PVP-Alliance",
		iconTexCoord = { 0, 0.5, 0, 0.59375 },
		accent = { 0.22, 0.48, 0.95 },
	},
}

local function getTrainerLocationText(trainer, includeCoords)
	if not trainer then
		return ""
	end

	local location = trainer.zone or ""
	if trainer.area and trainer.area ~= "" then
		location = location ~= "" and (trainer.area .. ", " .. location) or trainer.area
	end

	if includeCoords and trainer.coords and trainer.coords ~= "" then
		location = location ~= "" and (location .. " (" .. trainer.coords .. ")") or trainer.coords
	end

	return location
end

local function getImageSize(imageSize)
	if not imageSize then
		return nil, nil
	end

	return imageSize.width or imageSize[1], imageSize.height or imageSize[2]
end

local function fitImageSize(imageSize, maxWidth, maxHeight)
	local sourceWidth, sourceHeight = getImageSize(imageSize)
	if not sourceWidth or not sourceHeight or sourceWidth <= 0 or sourceHeight <= 0 then
		return maxWidth, maxHeight
	end

	local scale = math.min(maxWidth / sourceWidth, maxHeight / sourceHeight)
	return sourceWidth * scale, sourceHeight * scale
end

local function setTrainerImage(texture, trainer, imageWidth, imageHeight, fallbackSize)
	if trainer and trainer.targetImage then
		local width, height = fitImageSize(trainer.targetImageSize, imageWidth, imageHeight)

		texture:SetSize(width, height)
		texture:SetTexture(trainer.targetImage)
		texture:SetTexCoord(0, 1, 0, 1)
		return
	end

	local iconSize = fallbackSize or math.min(imageWidth, imageHeight)
	texture:SetSize(iconSize, iconSize)
	setIcon(texture, (trainer and trainer.icon) or TRAINER_FALLBACK_ICON)
end

local function setTrainerDetailImage(texture, imagePath, imageSize, maxWidth, maxHeight)
	if imagePath then
		local width, height = fitImageSize(imageSize, maxWidth or texture:GetWidth(), maxHeight or texture:GetHeight())

		texture:ClearAllPoints()
		texture:SetPoint("CENTER", texture:GetParent(), "CENTER", 0, 0)
		texture:SetSize(width, height)
		texture:SetTexture(imagePath)
		texture:SetTexCoord(0, 1, 0, 1)
		texture:Show()
		return true, width, height
	end

	texture:SetTexture(nil)
	texture:Hide()
	return false
end

local function createTrainerImageHoverHint(parent)
	local hint = CreateFrame("Frame", nil, parent, ns:GetBackdropTemplate())
	hint:SetSize(TRAINER_DETAIL_IMAGE_HINT_WIDTH, TRAINER_DETAIL_IMAGE_HINT_HEIGHT)
	hint:SetPoint("CENTER", parent, "CENTER", 0, 0)
	hint:SetFrameLevel((parent:GetFrameLevel() or 0) + 2)
	applyBackdrop(hint, BUTTON_BACKDROP, { 0.010, 0.010, 0.012, 0.52 }, { 0.42, 0.36, 0.24, 0.58 })
	hint:Hide()

	local text = hint:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", hint, "CENTER", 0, 0)
	text:SetText(TRAINER_DETAIL_IMAGE_HINT_TEXT)
	setTextColor(text, GOLD_SOFT)

	return hint
end

local function getTrainerImagePreviewConfig(imageKind, trainer)
	if imageKind == "map" then
		local startWidth, startHeight = fitImageSize(trainer and trainer.mapImageSize, TRAINER_DETAIL_MAP_WIDTH, TRAINER_DETAIL_MAP_HEIGHT)
		local targetWidth, targetHeight = fitImageSize(trainer and trainer.mapImageSize, TRAINER_DETAIL_MAP_PREVIEW_WIDTH, TRAINER_DETAIL_MAP_PREVIEW_HEIGHT)

		return {
			windowName = "trainerDetailMapPreview",
			startWidth = startWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
			startHeight = startHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
			targetWidth = targetWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
			targetHeight = targetHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		}
	end

	local startWidth, startHeight = fitImageSize(trainer and trainer.modelImageSize, TRAINER_DETAIL_MODEL_WIDTH, TRAINER_DETAIL_MODEL_HEIGHT)
	local targetWidth, targetHeight = fitImageSize(trainer and trainer.modelImageSize, TRAINER_DETAIL_MODEL_PREVIEW_WIDTH, TRAINER_DETAIL_MODEL_PREVIEW_HEIGHT)

	return {
		windowName = "trainerDetailModelPreview",
		startWidth = startWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		startHeight = startHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		targetWidth = targetWidth + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
		targetHeight = targetHeight + (TRAINER_DETAIL_PREVIEW_PADDING * 2),
	}
end

local function clamp(value, minimum, maximum)
	if value < minimum then
		return minimum
	end

	if value > maximum then
		return maximum
	end

	return value
end

local function hasTrainerTeaches(trainer)
	return trainer and trainer.teaches and #trainer.teaches > 0
end

local function getTrainerTeachName(teach)
	if not teach then
		return ""
	end

	if teach.rank and teach.rank ~= "" then
		return teach.name .. " - " .. teach.rank
	end

	return teach.name or ""
end

local function formatFirstAidSkill(skill)
	if not skill or skill <= 0 then
		return "No prior skill"
	end

	return "First Aid " .. tostring(skill)
end

local function formatTrainerTeachReagents(teach)
	if not teach or not teach.reagents or #teach.reagents == 0 then
		return "None"
	end

	local reagents = {}
	for index, reagent in ipairs(teach.reagents) do
		reagents[index] = reagent.name .. " x" .. tostring(reagent.quantity or 1)
	end

	return table.concat(reagents, ", ")
end

local function formatTrainerTeachCreates(teach)
	if not teach or not teach.creates then
		return nil
	end

	local quantity = teach.creates.quantity or 1
	if quantity > 1 then
		return teach.creates.name .. " x" .. tostring(quantity)
	end

	return teach.creates.name
end

local function getItemIcon(itemID, fallback)
	if itemID then
		local icon
		if C_Item and C_Item.GetItemIconByID then
			icon = C_Item.GetItemIconByID(itemID)
		elseif GetItemIcon then
			icon = GetItemIcon(itemID)
		end

		if icon then
			return icon
		end
	end

	return fallback or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function getTrainerTeachIcon(teach)
	local fallback = getSpellTexture(teach and teach.spellID, (teach and teach.icon) or TRAINER_FALLBACK_ICON)
	if teach and teach.creates and teach.creates.itemID then
		return getItemIcon(teach.creates.itemID, fallback)
	end

	return fallback
end

local function showItemTooltip(frame)
	if not frame or not GameTooltip then
		return
	end

	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	if frame.itemID then
		if GameTooltip.SetItemByID then
			GameTooltip:SetItemByID(frame.itemID)
		else
			GameTooltip:SetHyperlink("item:" .. tostring(frame.itemID))
		end
	elseif frame.reagentName then
		GameTooltip:SetText(frame.reagentName)
	end
	GameTooltip:Show()
end

local function hideItemTooltip()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

local function getTrainerTeachLines(teach)
	if not teach then
		return "", "", "", ""
	end

	local requirementLine = "Train: " .. formatFirstAidSkill(teach.requiredSkill)
	if teach.characterLevel then
		requirementLine = requirementLine .. "   Level " .. tostring(teach.characterLevel)
	end

	if teach.type == "rank" then
		return requirementLine,
			"Cap: First Aid " .. tostring(teach.skillCap or ""),
			teach.description or "",
			""
	end

	if teach.itemRequiredSkill then
		requirementLine = requirementLine .. "   Use: " .. formatFirstAidSkill(teach.itemRequiredSkill)
	end

	return requirementLine, "", "", ""
end

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

function ProfessionMenu:CreateTrainerTeachesButton(parent)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(TRAINER_TEACHES_BUTTON_WIDTH, TRAINER_TEACHES_BUTTON_HEIGHT)
	button:RegisterForClicks("LeftButtonUp")
	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.30, 0.30, 0.31, 1 })

	local highlight = createTint(button, GOLD[1], GOLD[2], GOLD[3], 0.24)
	local body = createBody(button)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(16, 16)
	icon:SetPoint("LEFT", body, "LEFT", 11, 0)
	setIcon(icon, "Interface\\Icons\\INV_Scroll_03")

	local label = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", icon, "RIGHT", 7, 0)
	label:SetWidth(96)
	label:SetJustifyH("LEFT")
	label:SetText("Teaches... >")
	setTextColor(label, TEXT)

	button.highlight = highlight
	button.label = label
	button:SetScript("OnEnter", function(teachesButton)
		teachesButton.highlight:SetAlpha(0.62)
		applyBackdrop(teachesButton, BUTTON_BACKDROP, { 0.047, 0.041, 0.026, 0.98 }, BORDER_BRIGHT)
		teachesButton.label:SetTextColor(1, 0.93, 0.66, 1)
	end)
	button:SetScript("OnLeave", function(teachesButton)
		teachesButton.highlight:SetAlpha(0)
		applyBackdrop(teachesButton, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.30, 0.30, 0.31, 1 })
		setTextColor(teachesButton.label, TEXT)
	end)
	button:SetScript("OnMouseDown", function(teachesButton)
		setBodyOffset(teachesButton, 1, -1)
	end)
	button:SetScript("OnMouseUp", function(teachesButton)
		setBodyOffset(teachesButton, 0, 0)
	end)
	button:SetScript("OnClick", function()
		self:GoToTrainerTeaches()
	end)

	return button
end

function ProfessionMenu:CreateTrainerTeachRow(parent)
	local row = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	row:SetSize(TRAINER_TEACH_ROW_WIDTH, TRAINER_TEACH_ROW_COLLAPSED_HEIGHT)
	row:RegisterForClicks("LeftButtonUp")
	if row.SetClipsChildren then
		row:SetClipsChildren(true)
	end
	applyBackdrop(row, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.22, 0.22, 0.23, 1 })

	local highlight = createTint(row, GOLD[1], GOLD[2], GOLD[3], 0.20)

	local stripe = row:CreateTexture(nil, "ARTWORK")
	stripe:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -5)
	stripe:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 5, 5)
	stripe:SetWidth(2)
	colorTexture(stripe, GOLD[1], GOLD[2], GOLD[3], 0.80)

	local iconFrame = CreateFrame("Frame", nil, row, ns:GetBackdropTemplate())
	iconFrame:SetSize(TRAINER_TEACH_ICON_SIZE + 8, TRAINER_TEACH_ICON_SIZE + 8)
	iconFrame:SetPoint("TOPLEFT", row, "TOPLEFT", 16, -6)
	applyBackdrop(iconFrame, BUTTON_BACKDROP, { 0.010, 0.010, 0.012, 0.92 }, { 0.28, 0.26, 0.22, 1 })

	local icon = iconFrame:CreateTexture(nil, "OVERLAY")
	icon:SetSize(TRAINER_TEACH_ICON_SIZE, TRAINER_TEACH_ICON_SIZE)
	icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)

	local iconButton = CreateFrame("Button", nil, iconFrame)
	iconButton:SetAllPoints(iconFrame)
	iconButton:RegisterForClicks("LeftButtonUp")
	iconButton:SetScript("OnEnter", function(button)
		row.hovered = true
		self:SetTrainerTeachRowState(row, row.index == self.selectedTrainerTeachIndex, true)
		if button.itemID then
			showItemTooltip(button)
		end
	end)
	iconButton:SetScript("OnLeave", function(button)
		hideItemTooltip()
		row.hovered = row.IsMouseOver and row:IsMouseOver()
		self:SetTrainerTeachRowState(row, row.index == self.selectedTrainerTeachIndex, row.hovered)
	end)
	iconButton:SetScript("OnClick", function()
		self:SelectTrainerTeach(row.index)
	end)

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 12, -1)
	name:SetWidth(254)
	name:SetJustifyH("LEFT")
	setTextColor(name, GOLD)

	local chevron = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	chevron:SetPoint("TOPRIGHT", row, "TOPRIGHT", -15, -14)
	chevron:SetWidth(18)
	chevron:SetJustifyH("CENTER")
	chevron:SetText("+")
	chevron:SetTextColor(0.56, 0.53, 0.46, 1)

	local line1 = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	line1:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
	line1:SetWidth(366)
	line1:SetJustifyH("LEFT")
	setTextColor(line1, TEXT)

	local divider = row:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", row, "TOPLEFT", 14, -52)
	divider:SetPoint("TOPRIGHT", row, "TOPRIGHT", -14, -52)
	divider:SetHeight(1)
	colorTexture(divider, 0.28, 0.26, 0.22, 0.86)

	local detail = CreateFrame("Frame", nil, row)
	detail:SetPoint("TOPLEFT", row, "TOPLEFT", 92, -64)
	detail:SetSize(340, 76)
	detail:Hide()

	local line2 = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	line2:SetPoint("TOPLEFT", detail, "TOPLEFT", 0, 0)
	line2:SetWidth(366)
	line2:SetJustifyH("LEFT")
	setTextColor(line2, TEXT_DIM)

	local createLabel = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	createLabel:SetWidth(48)
	createLabel:SetJustifyH("LEFT")
	createLabel:SetText("Creates:")
	setTextColor(createLabel, TEXT_DIM)
	createLabel:Hide()

	local createText = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	createText:SetWidth(240)
	createText:SetJustifyH("LEFT")
	setTextColor(createText, TEXT_DIM)
	createText:Hide()

	local reagentLabel = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	reagentLabel:SetWidth(62)
	reagentLabel:SetJustifyH("LEFT")
	reagentLabel:SetText("Reagents:")
	setTextColor(reagentLabel, TEXT_DIM)
	reagentLabel:Hide()

	local reagentText = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	reagentText:SetWidth(240)
	reagentText:SetJustifyH("LEFT")
	setTextColor(reagentText, TEXT_DIM)
	reagentText:Hide()

	local line3 = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	line3:SetPoint("TOPLEFT", line2, "BOTTOMLEFT", 0, -2)
	line3:SetWidth(366)
	line3:SetJustifyH("LEFT")
	setTextColor(line3, TEXT_DIM)

	local line4 = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	line4:SetPoint("TOPLEFT", line3, "BOTTOMLEFT", 0, -2)
	line4:SetWidth(366)
	line4:SetJustifyH("LEFT")
	setTextColor(line4, TEXT_DIM)

	row.highlight = highlight
	row.stripe = stripe
	row.iconButton = iconButton
	row.icon = icon
	row.name = name
	row.chevron = chevron
	row.line1 = line1
	row.line2 = line2
	row.line3 = line3
	row.line4 = line4
	row.divider = divider
	row.detail = detail
	row.createLabel = createLabel
	row.createText = createText
	row.createButton = nil
	row.reagentLabel = reagentLabel
	row.reagentText = reagentText
	row.reagentButtons = {}
	row.currentHeight = TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
	row.targetHeight = TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
	row:SetScript("OnEnter", function(teachRow)
		teachRow.hovered = true
		self:SetTrainerTeachRowState(teachRow, teachRow.index == self.selectedTrainerTeachIndex, true)
	end)
	row:SetScript("OnLeave", function(teachRow)
		teachRow.hovered = false
		self:SetTrainerTeachRowState(teachRow, teachRow.index == self.selectedTrainerTeachIndex, false)
	end)
	row:SetScript("OnClick", function(teachRow)
		self:SelectTrainerTeach(teachRow.index)
	end)

	return row
end

function ProfessionMenu:CreateTrainerReagentButton(parent)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(TRAINER_REAGENT_ICON_SIZE, TRAINER_REAGENT_ICON_SIZE)
	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp")
	applyBackdrop(button, BUTTON_BACKDROP, { 0.010, 0.010, 0.012, 0.92 }, { 0.30, 0.30, 0.31, 1 })

	local icon = button:CreateTexture(nil, "OVERLAY")
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)
	count:SetJustifyH("RIGHT")

	button.icon = icon
	button.count = count
	button:SetScript("OnEnter", showItemTooltip)
	button:SetScript("OnLeave", hideItemTooltip)
	button:Hide()

	return button
end

function ProfessionMenu:RefreshTrainerTeachReagents(row, teach)
	local reagents = teach and teach.reagents
	local hasReagents = reagents and #reagents > 0
	local creates = teach and teach.creates
	local hasCreates = creates and creates.itemID

	row.line2:ClearAllPoints()
	row.line3:ClearAllPoints()
	row.line4:ClearAllPoints()
	row.createLabel:ClearAllPoints()
	row.createText:ClearAllPoints()
	row.reagentLabel:ClearAllPoints()
	row.reagentText:ClearAllPoints()

	if row.createButton then
		row.createButton:Hide()
	end

	if not hasReagents then
		row.reagentLabel:Hide()
		row.reagentText:Hide()
		for _, button in ipairs(row.reagentButtons) do
			button:Hide()
		end
	else
		row.reagentLabel:Show()
	end

	if hasCreates then
		if not row.createButton then
			row.createButton = self:CreateTrainerReagentButton(row.detail)
		end

		row.line2:Hide()
		row.line3:Hide()
		row.line4:Hide()
		row.createLabel:SetPoint("TOPLEFT", row.detail, "TOPLEFT", 0, 0)
		row.createLabel:Show()
		row.createButton.itemID = creates.itemID
		row.createButton.reagentName = creates.name
		row.createButton.icon:SetTexture(getItemIcon(creates.itemID))
		row.createButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.createButton.count:SetText((creates.quantity and creates.quantity > 1) and tostring(creates.quantity) or "")
		row.createButton:ClearAllPoints()
		row.createButton:SetPoint("TOPLEFT", row.createLabel, "TOPRIGHT", 4, 1)
		row.createButton:Show()
		row.createText:SetText(formatTrainerTeachCreates(teach) or "")
		row.createText:SetPoint("LEFT", row.createButton, "RIGHT", 6, 0)
		row.createText:Show()
		row.reagentLabel:SetPoint("TOPLEFT", row.createLabel, "BOTTOMLEFT", 0, -12)
	else
		row.createLabel:Hide()
		row.createText:Hide()
		row.line2:SetPoint("TOPLEFT", row.detail, "TOPLEFT", 0, 0)
		row.line2:SetWidth(366)
		row.line2:Show()
		row.line3:SetPoint("TOPLEFT", row.line2, "BOTTOMLEFT", 0, -4)
		if row.line3:GetText() and row.line3:GetText() ~= "" then
			row.line3:Show()
		else
			row.line3:Hide()
		end
		row.line4:SetPoint("TOPLEFT", row.line3, "BOTTOMLEFT", 0, -4)
		row.reagentLabel:SetPoint("TOPLEFT", row.line3, "BOTTOMLEFT", 0, -10)
	end

	if not hasReagents then
		return
	end

	local anchor = row.reagentLabel
	for index, reagent in ipairs(reagents) do
		local button = row.reagentButtons[index]
		if not button then
			button = self:CreateTrainerReagentButton(row.detail)
			row.reagentButtons[index] = button
		end

		button.itemID = reagent.itemID
		button.reagentName = reagent.name
		button.icon:SetTexture(getItemIcon(reagent.itemID))
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button.count:SetText((reagent.quantity and reagent.quantity > 1) and tostring(reagent.quantity) or "")
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", anchor, "TOPRIGHT", index == 1 and 4 or TRAINER_REAGENT_ICON_GAP, 1)
		button:Show()
		anchor = button
	end

	row.reagentText:SetText(formatTrainerTeachReagents(teach))
	row.reagentText:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
	row.reagentText:Show()

	for index = #reagents + 1, #row.reagentButtons do
		row.reagentButtons[index]:Hide()
	end

	row.line3:SetPoint("TOPLEFT", row.reagentLabel, "BOTTOMLEFT", 0, -11)
	row.line4:SetPoint("TOPLEFT", row.line3, "BOTTOMLEFT", 0, -4)
end

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
	else
		self.trainerDetailMapHint:Hide()
		self.trainerDetailMapFrame:Hide()
		self.trainerDetailMapButton:Hide()
		self.trainerDetailWaypointButton:Hide()
	end
end

ProfessionMenu:RegisterCategoryInitializer(function(menu)
	menu:CreateTrainerMenuView()
	menu:CreateTrainerDetailView()
	menu:CreateTrainerTeachesView()
end)

ProfessionMenu:RegisterSectionHandler("trainers", function(menu)
	menu:GoToTrainerMenu()
end)
