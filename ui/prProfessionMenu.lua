local _, ns = ...

local ProfessionMenu = {}
ns.ProfessionMenu = ProfessionMenu

local ROOT_CARD_WIDTH = 430
local ROOT_CARD_HEIGHT = 58
local SCREEN_PADDING_X = 24
local HEADER_Y = -28
local GRID_Y = -80
local PROFESSION_ROW_WIDTH = 232
local PROFESSION_ROW_HEIGHT = 38
local PROFESSION_ROW_GAP = 8
local ACTION_WIDTH = 230
local ACTION_HEIGHT = 50
local ACTION_GAP = 9
local GOLD = { 1.00, 0.82, 0.00, 1 }
local GOLD_SOFT = { 0.92, 0.70, 0.20, 1 }
local TEXT = { 0.96, 0.92, 0.82, 1 }
local TEXT_DIM = { 0.66, 0.63, 0.55, 1 }
local BORDER = { 0.34, 0.34, 0.35, 1 }
local BORDER_BRIGHT = { 0.86, 0.76, 0.48, 1 }
local WINDOW_HORIZONTAL_INSET = 32

local WINDOW_SIZES = {
	root = {
		width = 500,
		height = 175,
	},
	professions = {
		width = 570,
		height = 475,
	},
	detail = {
		width = 570,
		height = 350,
	},
}

local BUTTON_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = false,
	edgeSize = 12,
	insets = {
		left = 2,
		right = 2,
		top = 2,
		bottom = 2,
	},
}

local function colorTexture(texture, r, g, b, a)
	if texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, a)
	else
		texture:SetTexture(r, g, b, a)
	end
end

local function applyBackdrop(frame, backdrop, backgroundColor, borderColor)
	if not frame.SetBackdrop then
		return
	end

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

local function setTextColor(fontString, color, alpha)
	fontString:SetTextColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function easeOutCubic(progress)
	local inverse = 1 - progress
	return 1 - (inverse * inverse * inverse)
end

local function setIcon(texture, icon)
	texture:SetTexture(icon)
	texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

local function getSpellTexture(spellID, fallback)
	local texture

	if C_Spell and C_Spell.GetSpellTexture then
		texture = C_Spell.GetSpellTexture(spellID)
	elseif GetSpellTexture then
		texture = GetSpellTexture(spellID)
	end

	if type(texture) == "table" then
		texture = texture.iconID or texture.icon or texture.texture
	end

	return texture or fallback
end

local function getActionGridHeight(sectionCount)
	local rows = math.ceil((sectionCount or 0) / 2)
	if rows <= 0 then
		return ACTION_HEIGHT
	end

	return (rows * ACTION_HEIGHT) + ((rows - 1) * ACTION_GAP)
end

local function createBody(button)
	local body = CreateFrame("Frame", nil, button)
	body:SetAllPoints(button)
	button.body = body

	return body
end

local function setBodyOffset(button, x, y)
	if not button.body then
		return
	end

	button.body:ClearAllPoints()
	button.body:SetPoint("TOPLEFT", button, "TOPLEFT", x, y)
	button.body:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", x, y)
end

local function createTint(parent, r, g, b, a)
	local tint = parent:CreateTexture(nil, "BACKGROUND")
	tint:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -3)
	tint:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 3)
	colorTexture(tint, r, g, b, a)
	tint:SetAlpha(0)

	return tint
end

local function createView(stage, name)
	local view = CreateFrame("Frame", "$parent" .. name, stage)
	view.parentStage = stage
	view:SetAllPoints(stage)
	view:Hide()

	return view
end

local function placeView(view, offsetX)
	view:ClearAllPoints()
	view:SetPoint("TOPLEFT", view.parentStage, "TOPLEFT", offsetX, 0)
	view:SetPoint("BOTTOMRIGHT", view.parentStage, "BOTTOMRIGHT", offsetX, 0)
end

function ProfessionMenu:Attach(window)
	if self.frame or not window or not window.content then
		return
	end

	self.frame = window
	self.content = window.content
	self.professions = ns.ProfessionData and ns.ProfessionData.professions or {}
	self.sections = ns.ProfessionData and ns.ProfessionData.menuSections or {}
	self.selectedProfession = self.professions[1]
	self.selectedSectionID = self.sections[1] and self.sections[1].id or nil
	self.professionButtons = {}
	self.actionButtons = {}
	self.views = {}

	self:CreateStage()
	self:CreateRootView()
	self:CreateProfessionListView()
	self:CreateProfessionDetailView()
	self:ShowInitialView()
end

function ProfessionMenu:CreateStage()
	local stage = CreateFrame("Frame", "$parentProfessionNavigator", self.content)
	stage:SetAllPoints(self.content)
	stage:SetFrameLevel(self.content:GetFrameLevel() + 8)
	if stage.SetClipsChildren then
		stage:SetClipsChildren(true)
	end

	self.stage = stage
end

function ProfessionMenu:CreateRootView()
	local view = createView(self.stage, "RootView")
	self.views.root = view

	local card = CreateFrame("Button", "$parentProfessionRootCard", view, ns:GetBackdropTemplate())
	card:SetSize(ROOT_CARD_WIDTH, ROOT_CARD_HEIGHT)
	card:SetPoint("TOPLEFT", view, "TOPLEFT", 18, -48)
	card:RegisterForClicks("LeftButtonUp")
	applyBackdrop(card, BUTTON_BACKDROP, { 0.020, 0.020, 0.022, 0.94 }, BORDER)

	local glow = createTint(card, GOLD[1], GOLD[2], GOLD[3], 0.26)
	local body = createBody(card)

	local iconFrame = body:CreateTexture(nil, "ARTWORK")
	iconFrame:SetSize(38, 38)
	iconFrame:SetPoint("LEFT", body, "LEFT", 14, 0)
	colorTexture(iconFrame, 0.03, 0.03, 0.03, 1)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(30, 30)
	icon:SetPoint("CENTER", iconFrame, "CENTER")
	setIcon(icon, ns.assets.icon)

	local title = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", iconFrame, "RIGHT", 16, 8)
	title:SetText("Professions")
	setTextColor(title, GOLD)

	local subtitle = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Classic paths")
	subtitle:SetTextColor(0.78, 0.73, 0.61, 1)

	local chevron = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	chevron:SetPoint("RIGHT", body, "RIGHT", -18, 0)
	chevron:SetText(">")
	setTextColor(chevron, GOLD_SOFT)

	card.glow = glow
	card:SetScript("OnEnter", function(button)
		button.glow:SetAlpha(0.72)
		applyBackdrop(button, BUTTON_BACKDROP, { 0.045, 0.039, 0.023, 0.98 }, BORDER_BRIGHT)
	end)
	card:SetScript("OnLeave", function(button)
		button.glow:SetAlpha(0)
		applyBackdrop(button, BUTTON_BACKDROP, { 0.020, 0.020, 0.022, 0.94 }, BORDER)
	end)
	card:SetScript("OnMouseDown", function(button)
		setBodyOffset(button, 1, -1)
	end)
	card:SetScript("OnMouseUp", function(button)
		setBodyOffset(button, 0, 0)
	end)
	card:SetScript("OnClick", function()
		self:GoToProfessions()
	end)

	self.rootCard = card
end

function ProfessionMenu:CreateBackButton(parent, onClick)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(84, 30)
	button:RegisterForClicks("LeftButtonUp")
	applyBackdrop(button, BUTTON_BACKDROP, { 0.026, 0.026, 0.028, 0.92 }, { 0.27, 0.27, 0.29, 1 })

	local glow = createTint(button, GOLD[1], GOLD[2], GOLD[3], 0.22)
	local body = createBody(button)

	local text = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", body, "CENTER", 0, 0)
	text:SetText("<  Back")
	text:SetTextColor(0.90, 0.86, 0.74, 1)

	button.glow = glow
	button:SetScript("OnEnter", function(backButton)
		backButton.glow:SetAlpha(0.64)
		applyBackdrop(backButton, BUTTON_BACKDROP, { 0.047, 0.041, 0.026, 0.98 }, BORDER_BRIGHT)
	end)
	button:SetScript("OnLeave", function(backButton)
		backButton.glow:SetAlpha(0)
		applyBackdrop(backButton, BUTTON_BACKDROP, { 0.026, 0.026, 0.028, 0.92 }, { 0.27, 0.27, 0.29, 1 })
	end)
	button:SetScript("OnMouseDown", function(backButton)
		setBodyOffset(backButton, 1, -1)
	end)
	button:SetScript("OnMouseUp", function(backButton)
		setBodyOffset(backButton, 0, 0)
	end)
	button:SetScript("OnClick", onClick)

	return button
end

function ProfessionMenu:CreateHeader(parent, titleText, subtitleText, onBack)
	local backButton = self:CreateBackButton(parent, onBack)
	backButton:SetPoint("TOPLEFT", parent, "TOPLEFT", SCREEN_PADDING_X, HEADER_Y + 4)

	local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", parent, "TOPLEFT", SCREEN_PADDING_X + 126, HEADER_Y - 1)
	title:SetText(titleText)
	setTextColor(title, GOLD)

	local subtitle = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText(subtitleText)
	subtitle:SetTextColor(0.70, 0.66, 0.56, 1)

	return title, subtitle
end

function ProfessionMenu:CreateProfessionListView()
	local view = createView(self.stage, "ProfessionsView")
	self.views.professions = view

	self:CreateHeader(view, "Professions", tostring(#self.professions) .. " Classic entries", function()
		self:GoToRoot()
	end)

	local grid = CreateFrame("Frame", nil, view)
	grid:SetSize(496, 310)
	grid:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_PADDING_X, GRID_Y)

	for index, profession in ipairs(self.professions) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local button = self:CreateProfessionRow(grid, profession)
		button:SetPoint("TOPLEFT", grid, "TOPLEFT", column * (PROFESSION_ROW_WIDTH + PROFESSION_ROW_GAP), -(row * (PROFESSION_ROW_HEIGHT + PROFESSION_ROW_GAP)))
		table.insert(self.professionButtons, button)
	end
end

function ProfessionMenu:CreateProfessionRow(parent, profession)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(PROFESSION_ROW_WIDTH, PROFESSION_ROW_HEIGHT)
	button:RegisterForClicks("LeftButtonUp")
	button.profession = profession
	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.22, 0.22, 0.23, 1 })

	local highlight = createTint(button, profession.accent[1], profession.accent[2], profession.accent[3], 0.26)
	local body = createBody(button)

	local stripe = body:CreateTexture(nil, "ARTWORK")
	stripe:SetPoint("TOPLEFT", body, "TOPLEFT", 5, -5)
	stripe:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 5, 5)
	stripe:SetWidth(2)
	colorTexture(stripe, profession.accent[1], profession.accent[2], profession.accent[3], 0.84)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(24, 24)
	icon:SetPoint("LEFT", body, "LEFT", 14, 0)
	setIcon(icon, getSpellTexture(profession.spellID, profession.icon))

	local name = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 9, -2)
	name:SetWidth(142)
	name:SetJustifyH("LEFT")
	name:SetText(profession.name)
	setTextColor(name, TEXT)

	local group = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	group:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
	group:SetWidth(142)
	group:SetJustifyH("LEFT")
	group:SetText(profession.group)
	setTextColor(group, TEXT_DIM)

	local chevron = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	chevron:SetPoint("RIGHT", body, "RIGHT", -12, 0)
	chevron:SetText(">")
	chevron:SetTextColor(0.56, 0.53, 0.46, 1)

	button.highlight = highlight
	button.name = name
	button.group = group
	button.chevron = chevron
	button:SetScript("OnEnter", function(rowButton)
		self:SetProfessionRowState(rowButton, rowButton.profession == self.selectedProfession, true)
	end)
	button:SetScript("OnLeave", function(rowButton)
		self:SetProfessionRowState(rowButton, rowButton.profession == self.selectedProfession, false)
	end)
	button:SetScript("OnMouseDown", function(rowButton)
		setBodyOffset(rowButton, 1, -1)
	end)
	button:SetScript("OnMouseUp", function(rowButton)
		setBodyOffset(rowButton, 0, 0)
	end)
	button:SetScript("OnClick", function(rowButton)
		self:GoToProfession(rowButton.profession)
	end)

	return button
end

function ProfessionMenu:CreateProfessionDetailView()
	local view = createView(self.stage, "ProfessionDetailView")
	self.views.detail = view

	local title, subtitle = self:CreateHeader(view, "Profession", "Choose a section", function()
		self:GoToProfessions(true)
	end)
	self.detailHeaderTitle = title
	self.detailHeaderSubtitle = subtitle

	local hero = CreateFrame("Frame", nil, view)
	hero:SetSize(482, 78)
	hero:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_PADDING_X, -78)

	local heroGlow = hero:CreateTexture(nil, "BACKGROUND")
	heroGlow:SetAllPoints(hero)
	colorTexture(heroGlow, 1, 0.82, 0.08, 0.08)

	local icon = hero:CreateTexture(nil, "OVERLAY")
	icon:SetSize(48, 48)
	icon:SetPoint("LEFT", hero, "LEFT", 14, 0)

	local name = hero:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 16, -6)
	name:SetWidth(330)
	name:SetJustifyH("LEFT")
	setTextColor(name, GOLD)

	local group = hero:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	group:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
	group:SetWidth(330)
	group:SetJustifyH("LEFT")
	group:SetTextColor(0.74, 0.70, 0.60, 1)

	local actionGrid = CreateFrame("Frame", nil, view)
	actionGrid:SetSize(492, getActionGridHeight(#self.sections))
	actionGrid:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_PADDING_X, -162)

	for index, section in ipairs(self.sections) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local button = self:CreateActionButton(actionGrid, section)
		button:SetPoint("TOPLEFT", actionGrid, "TOPLEFT", column * (ACTION_WIDTH + ACTION_GAP), -(row * (ACTION_HEIGHT + ACTION_GAP)))
		table.insert(self.actionButtons, button)
	end

	self.detailIcon = icon
	self.detailName = name
	self.detailGroup = group
	self.detailHeroGlow = heroGlow
end

function ProfessionMenu:CreateActionButton(parent, section)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(ACTION_WIDTH, ACTION_HEIGHT)
	button:RegisterForClicks("LeftButtonUp")
	button.section = section
	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, 0.90 }, { 0.22, 0.22, 0.23, 1 })

	local highlight = createTint(button, GOLD[1], GOLD[2], GOLD[3], 0.22)
	local body = createBody(button)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(26, 26)
	icon:SetPoint("LEFT", body, "LEFT", 16, 0)
	setIcon(icon, section.icon)

	local label = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", icon, "RIGHT", 12, 0)
	label:SetWidth(146)
	label:SetJustifyH("LEFT")
	label:SetText(section.label)
	setTextColor(label, TEXT)

	local chevron = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	chevron:SetPoint("RIGHT", body, "RIGHT", -12, 0)
	chevron:SetText(">")
	chevron:SetTextColor(0.56, 0.53, 0.46, 1)

	button.highlight = highlight
	button.label = label
	button.chevron = chevron
	button:SetScript("OnEnter", function(actionButton)
		self:SetActionButtonState(actionButton, actionButton.section.id == self.selectedSectionID, true)
	end)
	button:SetScript("OnLeave", function(actionButton)
		self:SetActionButtonState(actionButton, actionButton.section.id == self.selectedSectionID, false)
	end)
	button:SetScript("OnMouseDown", function(actionButton)
		setBodyOffset(actionButton, 1, -1)
	end)
	button:SetScript("OnMouseUp", function(actionButton)
		setBodyOffset(actionButton, 0, 0)
	end)
	button:SetScript("OnClick", function(actionButton)
		self:SelectSection(actionButton.section.id)
	end)

	return button
end

function ProfessionMenu:ShowInitialView()
	self:ResizeWindow("root", true)
	self.currentView = self.views.root
	self.currentViewName = "root"
	placeView(self.currentView, 0)
	self.currentView:SetAlpha(1)
	self.currentView:Show()
end

function ProfessionMenu:ResizeWindow(viewName, immediate)
	if not ns.Window or not ns.Window.ResizeTo then
		return
	end

	local size = WINDOW_SIZES[viewName]
	if not size then
		return
	end

	ns.Window:ResizeTo(size.width, size.height, immediate)
end

function ProfessionMenu:GetSlideDistance(targetName)
	local width = self.stage:GetWidth() or 0
	local targetSize = WINDOW_SIZES[targetName]
	if targetSize then
		width = math.max(width, targetSize.width - WINDOW_HORIZONTAL_INSET)
	end

	if not width or width < 40 then
		return 572
	end

	return width
end

function ProfessionMenu:TransitionTo(targetView, direction, targetName)
	if not targetView or self.animating or targetView == self.currentView then
		return
	end

	local oldView = self.currentView
	local distance = self:GetSlideDistance(targetName)
	local slideDirection = direction or 1
	local elapsedTime = 0
	local duration = 0.24

	self.animating = true
	self.stage:SetScript("OnUpdate", nil)
	targetView:Show()
	targetView:SetFrameLevel(self.stage:GetFrameLevel() + 2)
	if oldView then
		oldView:SetFrameLevel(self.stage:GetFrameLevel() + 1)
	end

	placeView(targetView, distance * slideDirection)
	targetView:SetAlpha(0.92)

	self.stage:SetScript("OnUpdate", function(stage, elapsed)
		elapsedTime = elapsedTime + elapsed
		local progress = math.min(elapsedTime / duration, 1)
		local eased = easeOutCubic(progress)

		placeView(targetView, (distance * slideDirection) * (1 - eased))
		targetView:SetAlpha(0.92 + (0.08 * eased))

		if oldView then
			placeView(oldView, -distance * slideDirection * eased)
			oldView:SetAlpha(1 - (0.16 * eased))
		end

		if progress >= 1 then
			stage:SetScript("OnUpdate", nil)
			if oldView then
				oldView:Hide()
				oldView:SetAlpha(1)
				placeView(oldView, 0)
			end

			placeView(targetView, 0)
			targetView:SetAlpha(1)
			self.currentView = targetView
			self.currentViewName = targetName
			self.animating = false
		end
	end)
end

function ProfessionMenu:GoToRoot()
	self:ResizeWindow("root")
	self:TransitionTo(self.views.root, -1, "root")
end

function ProfessionMenu:GoToProfessions(fromDetail)
	self:RefreshProfessionRows()
	self:ResizeWindow("professions")
	self:TransitionTo(self.views.professions, fromDetail and -1 or 1, "professions")
end

function ProfessionMenu:GoToProfession(profession)
	if not profession then
		return
	end

	self.selectedProfession = profession
	self:RefreshDetail()
	self:RefreshProfessionRows()
	self:ResizeWindow("detail")
	self:TransitionTo(self.views.detail, 1, "detail")
end

function ProfessionMenu:SetProfessionRowState(button, selected, hovered)
	local profession = button.profession
	local accent = profession.accent
	local borderColor = selected and { accent[1], accent[2], accent[3], 1 } or (hovered and BORDER_BRIGHT or { 0.22, 0.22, 0.23, 1 })

	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, selected and 0.96 or 0.90 }, borderColor)
	button.highlight:SetAlpha(selected and 0.66 or (hovered and 0.40 or 0))
	button.chevron:SetTextColor(hovered and 0.95 or 0.56, hovered and 0.83 or 0.53, hovered and 0.44 or 0.46, 1)

	if selected then
		button.name:SetTextColor(1, 0.93, 0.66, 1)
		button.group:SetTextColor(accent[1], accent[2], accent[3], 1)
	elseif hovered then
		button.name:SetTextColor(1, 0.96, 0.82, 1)
		button.group:SetTextColor(0.82, 0.78, 0.66, 1)
	else
		setTextColor(button.name, TEXT)
		setTextColor(button.group, TEXT_DIM)
	end
end

function ProfessionMenu:RefreshProfessionRows()
	for _, button in ipairs(self.professionButtons) do
		self:SetProfessionRowState(button, button.profession == self.selectedProfession, false)
	end
end

function ProfessionMenu:SetActionButtonState(button, selected, hovered)
	local profession = self.selectedProfession or self.professions[1]
	local accent = profession and profession.accent or GOLD
	local borderColor = selected and { accent[1], accent[2], accent[3], 1 } or (hovered and BORDER_BRIGHT or { 0.22, 0.22, 0.23, 1 })

	applyBackdrop(button, BUTTON_BACKDROP, { 0.018, 0.018, 0.020, selected and 0.96 or 0.90 }, borderColor)
	button.highlight:SetAlpha(selected and 0.56 or (hovered and 0.34 or 0))
	button.chevron:SetTextColor(hovered and 0.95 or 0.56, hovered and 0.83 or 0.53, hovered and 0.44 or 0.46, 1)

	if selected then
		button.label:SetTextColor(1, 0.93, 0.66, 1)
	elseif hovered then
		button.label:SetTextColor(1, 0.96, 0.82, 1)
	else
		setTextColor(button.label, TEXT)
	end
end

function ProfessionMenu:SelectSection(sectionID)
	self.selectedSectionID = sectionID
	self:RefreshActions()
end

function ProfessionMenu:RefreshActions()
	for _, button in ipairs(self.actionButtons) do
		self:SetActionButtonState(button, button.section.id == self.selectedSectionID, false)
	end
end

function ProfessionMenu:RefreshDetail()
	local profession = self.selectedProfession or self.professions[1]
	if not profession then
		return
	end

	setIcon(self.detailIcon, getSpellTexture(profession.spellID, profession.icon))
	self.detailName:SetText(profession.name)
	self.detailGroup:SetText(profession.group)
	self.detailHeaderTitle:SetText(profession.name)
	self.detailHeaderSubtitle:SetText("Choose a section")
	colorTexture(self.detailHeroGlow, profession.accent[1], profession.accent[2], profession.accent[3], 0.10)
	self:RefreshActions()
end
