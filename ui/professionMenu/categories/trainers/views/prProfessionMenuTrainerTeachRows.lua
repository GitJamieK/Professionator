local _, ns = ...

local ProfessionMenu = ns.ProfessionMenu
local Shared = ns.ProfessionMenuShared
local Trainers = ns.ProfessionMenuTrainers
local C = Trainers.Constants

local TRAINER_TEACHES_BUTTON_WIDTH = C.TRAINER_TEACHES_BUTTON_WIDTH
local TRAINER_TEACHES_BUTTON_HEIGHT = C.TRAINER_TEACHES_BUTTON_HEIGHT
local TRAINER_TEACH_ROW_WIDTH = C.TRAINER_TEACH_ROW_WIDTH
local TRAINER_TEACH_ROW_COLLAPSED_HEIGHT = C.TRAINER_TEACH_ROW_COLLAPSED_HEIGHT
local TRAINER_TEACH_ICON_SIZE = C.TRAINER_TEACH_ICON_SIZE
local TRAINER_REAGENT_ICON_SIZE = C.TRAINER_REAGENT_ICON_SIZE
local TRAINER_REAGENT_ICON_GAP = C.TRAINER_REAGENT_ICON_GAP
local BUTTON_BACKDROP = Shared.BUTTON_BACKDROP
local GOLD = Shared.Colors.GOLD
local TEXT = Shared.Colors.TEXT
local TEXT_DIM = Shared.Colors.TEXT_DIM
local BORDER_BRIGHT = Shared.Colors.BORDER_BRIGHT
local colorTexture = Shared.ColorTexture
local applyBackdrop = Shared.ApplyBackdrop
local setTextColor = Shared.SetTextColor
local setIcon = Shared.SetIcon
local createBody = Shared.CreateBody
local setBodyOffset = Shared.SetBodyOffset
local createTint = Shared.CreateTint
local formatTrainerTeachReagents = Trainers.FormatTrainerTeachReagents
local formatTrainerTeachCreates = Trainers.FormatTrainerTeachCreates
local getItemIcon = Trainers.GetItemIcon
local showItemTooltip = Trainers.ShowItemTooltip
local hideItemTooltip = Trainers.HideItemTooltip

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
