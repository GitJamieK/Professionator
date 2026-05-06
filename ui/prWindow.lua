local _, ns = ...

local Window = {}
ns.Window = Window

local FRAME_NAME = "ProfessionatorFrame"
local DEFAULT_WIDTH = 500
local DEFAULT_HEIGHT = 175
local RESIZE_DURATION = 0.24
local BORDER_COLOR = { 0.62, 0.62, 0.62, 1 }

local FRAME_BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
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

local PANEL_BACKDROP = {
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

local function applyBackdrop(frame, backdrop, backgroundColor, borderColor)
	if not frame.SetBackdrop then
		return
	end

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

local function registerSpecialFrame(frameName)
	if not UISpecialFrames then
		return
	end

	for _, existingFrameName in ipairs(UISpecialFrames) do
		if existingFrameName == frameName then
			return
		end
	end

	table.insert(UISpecialFrames, frameName)
end

local function startMoving(widget)
	local owner = widget.ownerFrame or widget
	owner:StartMoving()
end

local function stopMoving(widget)
	local owner = widget.ownerFrame or widget
	owner:StopMovingOrSizing()
	Window:SavePosition()
end

local function easeOutCubic(progress)
	local inverse = 1 - progress
	return 1 - (inverse * inverse * inverse)
end

local function anchorTopLeft(frame)
	if not frame or not UIParent then
		return
	end

	local left = frame:GetLeft()
	local top = frame:GetTop()
	local parentTop = UIParent:GetTop()
	if not left or not top or not parentTop then
		return
	end

	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, top - parentTop)
end

function Window:Create()
	if self.frame then
		return self.frame
	end

	local frame = CreateFrame("Frame", FRAME_NAME, UIParent, ns:GetBackdropTemplate())
	frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame.ownerFrame = frame
	frame:SetScript("OnDragStart", startMoving)
	frame:SetScript("OnDragStop", stopMoving)

	applyBackdrop(frame, FRAME_BACKDROP, { 0.02, 0.02, 0.02, 0.96 }, BORDER_COLOR)

	local titleBar = CreateFrame("Frame", "$parentTitleBar", frame, ns:GetBackdropTemplate())
	titleBar:SetSize(188, 28)
	titleBar:SetPoint("TOP", frame, "TOP", 0, -8)
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	titleBar.ownerFrame = frame
	titleBar:SetScript("OnDragStart", startMoving)
	titleBar:SetScript("OnDragStop", stopMoving)
	applyBackdrop(titleBar, PANEL_BACKDROP, { 0.015, 0.015, 0.015, 0.98 }, BORDER_COLOR)

	local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	titleText:SetPoint("CENTER", titleBar, "CENTER", 10, 0)
	titleText:SetText(ns.title)
	titleText:SetTextColor(1, 0.82, 0, 1)

	local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
	titleIcon:SetSize(16, 16)
	titleIcon:SetPoint("RIGHT", titleText, "LEFT", -4, 0)
	titleIcon:SetTexture(ns.assets.icon)

	local closeButton = CreateFrame("Button", "$parentCloseButton", frame, "UIPanelCloseButton")
	closeButton:SetSize(24, 24)
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)

	local content = CreateFrame("Frame", "$parentContent", frame)
	content:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -42)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)

	frame.content = content
	frame.closeButton = closeButton
	frame.titleBar = titleBar
	frame:Hide()

	self.frame = frame
	self:RestorePosition()
	registerSpecialFrame(FRAME_NAME)

	return frame
end

function Window:GetFrame()
	return self:Create()
end

function Window:RestorePosition()
	local frame = self.frame
	if not frame then
		return
	end

	local db = ns:GetDB().profile.window
	frame:ClearAllPoints()
	frame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER", db.x or 0, db.y or 0)
end

function Window:SavePosition()
	local frame = self.frame
	if not frame then
		return
	end

	local db = ns:GetDB().profile.window
	local point, _, relativePoint, x, y = frame:GetPoint(1)

	db.point = point or "CENTER"
	db.relativePoint = relativePoint or "CENTER"
	db.x = x or 0
	db.y = y or 0
end

function Window:ResizeTo(width, height, immediate)
	local frame = self:Create()
	if not frame or not width or not height then
		return
	end

	local currentWidth = frame:GetWidth() or width
	local currentHeight = frame:GetHeight() or height
	if math.abs(currentWidth - width) < 1 and math.abs(currentHeight - height) < 1 then
		frame:SetSize(width, height)
		return
	end

	anchorTopLeft(frame)

	if immediate or not frame:IsShown() then
		frame:SetSize(width, height)
		return
	end

	frame.resizeElapsed = 0
	frame.resizeStartWidth = currentWidth
	frame.resizeStartHeight = currentHeight
	frame.resizeTargetWidth = width
	frame.resizeTargetHeight = height
	frame:SetScript("OnUpdate", function(activeFrame, elapsed)
		activeFrame.resizeElapsed = activeFrame.resizeElapsed + elapsed
		local progress = math.min(activeFrame.resizeElapsed / RESIZE_DURATION, 1)
		local eased = easeOutCubic(progress)
		local nextWidth = activeFrame.resizeStartWidth + ((activeFrame.resizeTargetWidth - activeFrame.resizeStartWidth) * eased)
		local nextHeight = activeFrame.resizeStartHeight + ((activeFrame.resizeTargetHeight - activeFrame.resizeStartHeight) * eased)

		activeFrame:SetSize(nextWidth, nextHeight)

		if progress >= 1 then
			activeFrame:SetScript("OnUpdate", nil)
			activeFrame:SetSize(activeFrame.resizeTargetWidth, activeFrame.resizeTargetHeight)
		end
	end)
end

function Window:Show()
	self:Create():Show()
end

function Window:Hide()
	self:Create():Hide()
end

function Window:Toggle()
	local frame = self:Create()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end
