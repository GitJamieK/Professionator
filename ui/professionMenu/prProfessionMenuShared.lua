local _, ns = ...

local Shared = {}
ns.ProfessionMenuShared = Shared

Shared.ROOT_CARD_WIDTH = 430
Shared.ROOT_CARD_HEIGHT = 58
Shared.SCREEN_PADDING_X = 24
Shared.HEADER_Y = -28
Shared.GRID_Y = -80
Shared.PROFESSION_ROW_WIDTH = 232
Shared.PROFESSION_ROW_HEIGHT = 38
Shared.PROFESSION_ROW_GAP = 8
Shared.ACTION_WIDTH = 230
Shared.ACTION_HEIGHT = 50
Shared.ACTION_GAP = 9
Shared.WINDOW_HORIZONTAL_INSET = 32

Shared.Colors = {
	GOLD = { 1.00, 0.82, 0.00, 1 },
	GOLD_SOFT = { 0.92, 0.70, 0.20, 1 },
	TEXT = { 0.96, 0.92, 0.82, 1 },
	TEXT_DIM = { 0.66, 0.63, 0.55, 1 },
	BORDER = { 0.34, 0.34, 0.35, 1 },
	BORDER_BRIGHT = { 0.86, 0.76, 0.48, 1 },
}

Shared.WindowSizes = {
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

Shared.BUTTON_BACKDROP = {
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

function Shared.RegisterWindowSize(name, width, height)
	Shared.WindowSizes[name] = {
		width = width,
		height = height,
	}
end

function Shared.GetWindowSize(name)
	return Shared.WindowSizes[name]
end

function Shared.ColorTexture(texture, r, g, b, a)
	if texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, a)
	else
		texture:SetTexture(r, g, b, a)
	end
end

function Shared.ApplyBackdrop(frame, backdrop, backgroundColor, borderColor)
	if not frame.SetBackdrop then
		return
	end

	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

function Shared.SetTextColor(fontString, color, alpha)
	fontString:SetTextColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

function Shared.EaseOutCubic(progress)
	local inverse = 1 - progress
	return 1 - (inverse * inverse * inverse)
end

function Shared.SetIcon(texture, icon)
	texture:SetTexture(icon)
	texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

function Shared.SetTextureCoordinates(texture, texCoord)
	if not texCoord then
		return
	end

	texture:SetTexCoord(texCoord[1], texCoord[2], texCoord[3], texCoord[4])
end

function Shared.GetSpellTexture(spellID, fallback)
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

function Shared.GetActionGridHeight(sectionCount)
	local rows = math.ceil((sectionCount or 0) / 2)
	if rows <= 0 then
		return Shared.ACTION_HEIGHT
	end

	return (rows * Shared.ACTION_HEIGHT) + ((rows - 1) * Shared.ACTION_GAP)
end

function Shared.CreateBody(button)
	local body = CreateFrame("Frame", nil, button)
	body:SetAllPoints(button)
	button.body = body

	return body
end

function Shared.SetBodyOffset(button, x, y)
	if not button.body then
		return
	end

	button.body:ClearAllPoints()
	button.body:SetPoint("TOPLEFT", button, "TOPLEFT", x, y)
	button.body:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", x, y)
end

function Shared.CreateTint(parent, r, g, b, a)
	local tint = parent:CreateTexture(nil, "BACKGROUND")
	tint:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -3)
	tint:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 3)
	Shared.ColorTexture(tint, r, g, b, a)
	tint:SetAlpha(0)

	return tint
end

function Shared.CreateView(stage, name)
	local view = CreateFrame("Frame", "$parent" .. name, stage)
	view.parentStage = stage
	view:SetAllPoints(stage)
	view:Hide()

	return view
end

function Shared.PlaceView(view, offsetX)
	view:ClearAllPoints()
	view:SetPoint("TOPLEFT", view.parentStage, "TOPLEFT", offsetX, 0)
	view:SetPoint("BOTTOMRIGHT", view.parentStage, "BOTTOMRIGHT", offsetX, 0)
end
