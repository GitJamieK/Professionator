local _, ns = ...

local ProfessionMenu = {}
ns.ProfessionMenu = ProfessionMenu

local ROOT_CARD_WIDTH = 396
local ROOT_CARD_HEIGHT = 56
local SCREEN_MARGIN_X = 22
local SCREEN_MARGIN_Y = 18
local PROFESSION_ROW_WIDTH = 232
local PROFESSION_ROW_HEIGHT = 38
local PROFESSION_ROW_GAP = 8
local ACTION_WIDTH = 232
local ACTION_HEIGHT = 50
local ACTION_GAP = 10
local GOLD = { 1.00, 0.82, 0.00, 1 }
local GOLD_SOFT = { 0.92, 0.70, 0.20, 1 }
local TEXT = { 0.96, 0.92, 0.82, 1 }
local TEXT_DIM = { 0.66, 0.63, 0.55, 1 }
local BORDER = { 0.40, 0.40, 0.40, 1 }
local BORDER_BRIGHT = { 0.84, 0.73, 0.47, 1 }

local SURFACE_BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = {
		left = 4,
		right = 4,
		top = 4,
		bottom = 4,
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

local function smoothStep(progress)
	return progress * progress * (3 - (2 * progress))
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

local function setBodyOffset(button, x, y)
	local body = button.body
	if not body then
		return
	end

	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", button, "TOPLEFT", x, y)
	body:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", x, y)
end

local function createBody(button)
	local body = CreateFrame("Frame", nil, button)
	body:SetAllPoints(button)
	button.body = body

	return body
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
	self.window = window
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
	card:SetPoint("TOPLEFT", view, "TOPLEFT", 34, -70)
	card:RegisterForClicks("LeftButtonUp")
	applyBackdrop(card, BUTTON_BACKDROP, { 0.025, 0.025, 0.025, 0.95 }, BORDER)

	local glow = createTint(card, GOLD[1], GOLD[2], GOLD[3], 0.32)
	local body = createBody(card)

	local iconFrame = body:CreateTexture(nil, "ARTWORK")
	iconFrame:SetSize(38, 38)
	iconFrame:SetPoint("LEFT", body, "LEFT", 12, 0)
	colorTexture(iconFrame, 0.03, 0.03, 0.03, 1)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(30, 30)
	icon:SetPoint("CENTER", iconFrame, "CENTER")
	setIcon(icon, ns.assets.icon)

	local title = body:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", iconFrame, "RIGHT", 14, 7)
	title:SetText("Professions")
	setTextColor(title, GOLD)

	local subtitle = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText("Classic paths")
	subtitle:SetTextColor(0.78, 0.73, 0.61, 1)

	local chevron = body:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	chevron:SetPoint("RIGHT", body, "RIGHT", -16, 0)
	chevron:SetText(">")
	setTextColor(chevron, GOLD_SOFT)

	local rule = body:CreateTexture(nil, "OVERLAY")
	rule:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 14, 8)
	rule:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -14, 8)
	rule:SetHeight(1)
	colorTexture(rule, GOLD[1], GOLD[2], GOLD[3], 0.46)

	card.glow = glow
	card:SetScript("OnEnter", function(button)
		button.glow:SetAlpha(0.75)
		applyBackdrop(button, BUTTON_BACKDROP, { 0.05, 0.045, 0.025, 0.98 }, BORDER_BRIGHT)
	end)
	card:SetScript("OnLeave", function(button)
		button.glow:SetAlpha(0)
		applyBackdrop(button, BUTTON_BACKDROP, { 0.025, 0.025, 0.025, 0.95 }, BORDER)
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

function ProfessionMenu:CreateScreenSurface(view)
	local surface = CreateFrame("Frame", nil, view, ns:GetBackdropTemplate())
	surface:SetPoint("TOPLEFT", view, "TOPLEFT", SCREEN_MARGIN_X, -SCREEN_MARGIN_Y)
	surface:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", -SCREEN_MARGIN_X, SCREEN_MARGIN_Y)
	applyBackdrop(surface, SURFACE_BACKDROP, { 0.012, 0.012, 0.014, 0.95 }, BORDER)

	local topTint = surface:CreateTexture(nil, "BACKGROUND")
	topTint:SetPoint("TOPLEFT", surface, "TOPLEFT", 5, -5)
	topTint:SetPoint("TOPRIGHT", surface, "TOPRIGHT", -5, -5)
	topTint:SetHeight(82)
	colorTexture(topTint, 0.12, 0.10, 0.07, 0.30)

	local bottomLine = surface:CreateTexture(nil, "ARTWORK")
	bottomLine:SetPoint("BOTTOM", surface, "BOTTOM", 0, 10)
	bottomLine:SetSize(82, 1)
	colorTexture(bottomLine, 1, 1, 1, 0.16)

	return surface
end

function ProfessionMenu:CreateBackButton(parent, label, onClick)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(78, 28)
	button:RegisterForClicks("LeftButtonUp")
	applyBackdrop(button, BUTTON_BACKDROP, { 0.032, 0.032, 0.035, 0.92 }, { 0.30, 0.30, 0.32, 1 })

	local glow = createTint(button, GOLD[1], GOLD[2], GOLD[3], 0.24)
	local body = createBody(button)

	local arrow = body:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	arrow:SetPoint("LEFT", body, "LEFT", 10, 0)
	arrow:SetText("<")
	setTextColor(arrow, GOLD_SOFT)

	local text = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
	text:SetText(label or "Back")
	text:SetTextColor(0.90, 0.86, 0.74, 1)

	button.glow = glow
	button:SetScript("OnEnter", function(backButton)
		backButton.glow:SetAlpha(0.65)
		applyBackdrop(backButton, BUTTON_BACKDROP, { 0.055, 0.048, 0.030, 0.98 }, BORDER_BRIGHT)
	end)
	button:SetScript("OnLeave", function(backButton)
		backButton.glow:SetAlpha(0)
		applyBackdrop(backButton, BUTTON_BACKDROP, { 0.032, 0.032, 0.035, 0.92 }, { 0.30, 0.30, 0.32, 1 })
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

function ProfessionMenu:CreateHeader(surface, titleText, subtitleText, backLabel, onBack)
	local backButton = self:CreateBackButton(surface, backLabel, onBack)
	backButton:SetPoint("TOPLEFT", surface, "TOPLEFT", 14, -14)

	local title = surface:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", surface, "TOPLEFT", 108, -15)
	title:SetText(titleText)
	setTextColor(title, GOLD)

	local subtitle = surface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	subtitle:SetText(subtitleText)
	subtitle:SetTextColor(0.70, 0.66, 0.56, 1)

	local rule = surface:CreateTexture(nil, "ARTWORK")
	rule:SetPoint("TOPLEFT", surface, "TOPLEFT", 14, -62)
	rule:SetPoint("TOPRIGHT", surface, "TOPRIGHT", -14, -62)
	rule:SetHeight(1)
	colorTexture(rule, GOLD[1], GOLD[2], GOLD[3], 0.26)

	return title, subtitle, rule
end

function ProfessionMenu:CreateProfessionListView()
	local view = createView(self.stage, "ProfessionsView")
	self.views.professions = view

	local surface = self:CreateScreenSurface(view)
	self:CreateHeader(surface, "Professions", tostring(#self.professions) .. " Classic entries", "Back", function()
		self:GoToRoot()
	end)

	local grid = CreateFrame("Frame", nil, surface)
	grid:SetSize(490, 314)
	grid:SetPoint("TOPLEFT", surface, "TOPLEFT", 22, -78)

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
	applyBackdrop(button, BUTTON_BACKDROP, { 0.022, 0.022, 0.025, 0.88 }, { 0.24, 0.24, 0.25, 1 })

	local highlight = createTint(button, profession.accent[1], profession.accent[2], profession.accent[3], 0.25)
	local body = createBody(button)

	local stripe = body:CreateTexture(nil, "ARTWORK")
	stripe:SetPoint("TOPLEFT", body, "TOPLEFT", 5, -5)
	stripe:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", 5, 5)
	stripe:SetWidth(2)
	colorTexture(stripe, profession.accent[1], profession.accent[2], profession.accent[3], 0.82)

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

	local surface = self:CreateScreenSurface(view)
	local title, subtitle = self:CreateHeader(surface, "Profession", "Tools and routes", "Back", function()
		self:GoToProfessions(true)
	end)
	self.detailHeaderTitle = title
	self.detailHeaderSubtitle = subtitle

	local hero = CreateFrame("Frame", nil, surface)
	hero:SetSize(494, 72)
	hero:SetPoint("TOPLEFT", surface, "TOPLEFT", 18, -78)

	local heroGlow = hero:CreateTexture(nil, "BACKGROUND")
	heroGlow:SetAllPoints(hero)
	colorTexture(heroGlow, 1, 0.82, 0.08, 0.08)

	local icon = hero:CreateTexture(nil, "OVERLAY")
	icon:SetSize(46, 46)
	icon:SetPoint("LEFT", hero, "LEFT", 12, 0)

	local name = hero:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, -4)
	name:SetWidth(330)
	name:SetJustifyH("LEFT")
	setTextColor(name, GOLD)

	local group = hero:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	group:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
	group:SetWidth(330)
	group:SetJustifyH("LEFT")
	group:SetTextColor(0.74, 0.70, 0.60, 1)

	local heroRule = hero:CreateTexture(nil, "ARTWORK")
	heroRule:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 12, 4)
	heroRule:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -12, 4)
	heroRule:SetHeight(1)
	colorTexture(heroRule, GOLD[1], GOLD[2], GOLD[3], 0.28)

	local actionGrid = CreateFrame("Frame", nil, surface)
	actionGrid:SetSize(494, 230)
	actionGrid:SetPoint("TOPLEFT", surface, "TOPLEFT", 18, -154)

	for index, section in ipairs(self.sections) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		local button = self:CreateActionButton(actionGrid, section)
		button:SetPoint("TOPLEFT", actionGrid, "TOPLEFT", column * (ACTION_WIDTH + ACTION_GAP), -(row * (ACTION_HEIGHT + ACTION_GAP)))
		table.insert(self.actionButtons, button)
	end

	local status = surface:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("BOTTOMLEFT", surface, "BOTTOMLEFT", 22, 16)
	status:SetPoint("BOTTOMRIGHT", surface, "BOTTOMRIGHT", -22, 16)
	status:SetJustifyH("LEFT")
	status:SetTextColor(0.90, 0.84, 0.64, 1)

	self.detailIcon = icon
	self.detailName = name
	self.detailGroup = group
	self.detailHeroRule = heroRule
	self.detailHeroGlow = heroGlow
	self.status = status
end

function ProfessionMenu:CreateActionButton(parent, section)
	local button = CreateFrame("Button", nil, parent, ns:GetBackdropTemplate())
	button:SetSize(ACTION_WIDTH, ACTION_HEIGHT)
	button:RegisterForClicks("LeftButtonUp")
	button.section = section
	applyBackdrop(button, BUTTON_BACKDROP, { 0.022, 0.022, 0.025, 0.90 }, { 0.24, 0.24, 0.25, 1 })

	local highlight = createTint(button, GOLD[1], GOLD[2], GOLD[3], 0.22)
	local body = createBody(button)

	local icon = body:CreateTexture(nil, "OVERLAY")
	icon:SetSize(24, 24)
	icon:SetPoint("LEFT", body, "LEFT", 14, 0)
	setIcon(icon, section.icon)

	local label = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", icon, "RIGHT", 10, 5)
	label:SetWidth(160)
	label:SetJustifyH("LEFT")
	label:SetText(section.label)
	setTextColor(label, TEXT)

	local hint = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -1)
	hint:SetWidth(160)
	hint:SetJustifyH("LEFT")
	hint:SetText("Open")
	setTextColor(hint, TEXT_DIM)

	local chevron = body:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	chevron:SetPoint("RIGHT", body, "RIGHT", -12, 0)
	chevron:SetText(">")
	chevron:SetTextColor(0.56, 0.53, 0.46, 1)

	button.highlight = highlight
	button.label = label
	button.hint = hint
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
	self.currentView = self.views.root
	self.currentViewName = "root"
	placeView(self.currentView, 0)
	self.currentView:SetAlpha(1)
	self.currentView:Show()
	self:StaggerButtons({ self.rootCard }, 0.03)
end

function ProfessionMenu:GetSlideDistance()
	local width = self.stage:GetWidth()
	if not width or width < 40 then
		return 576
	end

	return width
end

function ProfessionMenu:TransitionTo(targetView, direction, targetName)
	if not targetView or self.animating or targetView == self.currentView then
		return
	end

	local oldView = self.currentView
	local distance = self:GetSlideDistance()
	local slideDirection = direction or 1

	self.animating = true
	self.stage:SetScript("OnUpdate", nil)
	targetView:Show()
	targetView:SetFrameLevel(self.stage:GetFrameLevel() + 2)
	if oldView then
		oldView:SetFrameLevel(self.stage:GetFrameLevel() + 1)
	end

	placeView(targetView, distance * slideDirection)
	targetView:SetAlpha(0.55)

	local elapsedTime = 0
	local duration = 0.24
	self.stage:SetScript("OnUpdate", function(stage, elapsed)
		elapsedTime = elapsedTime + elapsed
		local progress = math.min(elapsedTime / duration, 1)
		local eased = easeOutCubic(progress)

		placeView(targetView, (distance * slideDirection) * (1 - eased))
		targetView:SetAlpha(0.55 + (0.45 * eased))

		if oldView then
			placeView(oldView, -distance * slideDirection * eased)
			oldView:SetAlpha(1 - (0.42 * eased))
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
			self:RunEntryAnimation(targetName)
		end
	end)
end

function ProfessionMenu:RunEntryAnimation(viewName)
	if viewName == "root" then
		self:StaggerButtons({ self.rootCard }, 0.03)
	elseif viewName == "professions" then
		self:RefreshProfessionRows()
		self:StaggerButtons(self.professionButtons, 0.012)
	elseif viewName == "detail" then
		self:RefreshDetail()
		self:StaggerButtons(self.actionButtons, 0.018)
	end
end

function ProfessionMenu:StaggerButtons(buttons, delayStep)
	for index, button in ipairs(buttons) do
		button:SetAlpha(0)
		button.entryElapsed = 0
		button.entryDelay = (index - 1) * delayStep
		button:SetScript("OnUpdate", function(entryButton, elapsed)
			entryButton.entryElapsed = entryButton.entryElapsed + elapsed
			local progress = (entryButton.entryElapsed - entryButton.entryDelay) / 0.16

			if progress <= 0 then
				entryButton:SetAlpha(0)
				return
			end

			progress = math.min(progress, 1)
			entryButton:SetAlpha(smoothStep(progress))

			if progress >= 1 then
				entryButton:SetScript("OnUpdate", nil)
			end
		end)
	end
end

function ProfessionMenu:GoToRoot()
	self:TransitionTo(self.views.root, -1, "root")
end

function ProfessionMenu:GoToProfessions(fromDetail)
	self:TransitionTo(self.views.professions, fromDetail and -1 or 1, "professions")
end

function ProfessionMenu:GoToProfession(profession)
	if not profession then
		return
	end

	self.selectedProfession = profession
	self:RefreshDetail()
	self:RefreshProfessionRows()
	self:TransitionTo(self.views.detail, 1, "detail")
end

function ProfessionMenu:SetProfessionRowState(button, selected, hovered)
	local profession = button.profession
	local accent = profession.accent
	local borderColor = selected and { accent[1], accent[2], accent[3], 1 } or (hovered and BORDER_BRIGHT or { 0.24, 0.24, 0.25, 1 })

	applyBackdrop(button, BUTTON_BACKDROP, { 0.022, 0.022, 0.025, selected and 0.96 or 0.88 }, borderColor)
	button.highlight:SetAlpha(selected and 0.72 or (hovered and 0.46 or 0))
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
	local borderColor = selected and { accent[1], accent[2], accent[3], 1 } or (hovered and BORDER_BRIGHT or { 0.24, 0.24, 0.25, 1 })

	applyBackdrop(button, BUTTON_BACKDROP, { 0.022, 0.022, 0.025, selected and 0.96 or 0.90 }, borderColor)
	button.highlight:SetAlpha(selected and 0.58 or (hovered and 0.34 or 0))
	button.chevron:SetTextColor(hovered and 0.95 or 0.56, hovered and 0.83 or 0.53, hovered and 0.44 or 0.46, 1)

	if selected then
		button.label:SetTextColor(1, 0.93, 0.66, 1)
		button.hint:SetTextColor(accent[1], accent[2], accent[3], 1)
	elseif hovered then
		button.label:SetTextColor(1, 0.96, 0.82, 1)
		button.hint:SetTextColor(0.82, 0.78, 0.66, 1)
	else
		setTextColor(button.label, TEXT)
		setTextColor(button.hint, TEXT_DIM)
	end
end

function ProfessionMenu:SelectSection(sectionID)
	self.selectedSectionID = sectionID
	self:RefreshActions()
	self:RefreshStatus()
end

function ProfessionMenu:RefreshActions()
	for _, button in ipairs(self.actionButtons) do
		self:SetActionButtonState(button, button.section.id == self.selectedSectionID, false)
	end
end

function ProfessionMenu:GetSelectedSection()
	for _, section in ipairs(self.sections) do
		if section.id == self.selectedSectionID then
			return section
		end
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
	colorTexture(self.detailHeroRule, profession.accent[1], profession.accent[2], profession.accent[3], 0.42)
	colorTexture(self.detailHeroGlow, profession.accent[1], profession.accent[2], profession.accent[3], 0.10)
	self:RefreshActions()
	self:RefreshStatus()
end

function ProfessionMenu:RefreshStatus()
	if not self.status or not self.selectedProfession then
		return
	end

	local section = self:GetSelectedSection()
	local sectionLabel = section and section.label or "Overview"
	self.status:SetText(self.selectedProfession.name .. " / " .. sectionLabel)
end
