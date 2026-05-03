local _, ns = ...

local MinimapButton = {}
ns.Minimap = MinimapButton

local DATA_OBJECT_NAME = "Professionator"

local function onTooltipShow(tooltip)
	if not tooltip or not tooltip.AddLine then
		return
	end

	tooltip:AddLine(ns.title, 1, 0.82, 0)
	tooltip:AddLine("Click: Open/Close", 1, 1, 1)
	tooltip:AddLine("Drag: Move icon", 1, 1, 1)
end

local function onClick(_, button)
	if button == "LeftButton" or button == "RightButton" then
		ns.UI:ToggleWindow()
	end
end

function MinimapButton:Initialize()
	if self.initialized then
		return
	end

	local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
	local dbIcon = LibStub and LibStub("LibDBIcon-1.0", true)

	if not ldb or not dbIcon then
		ns:Print("LibDBIcon-1.0 could not be loaded.")
		return
	end

	local dataObject = ldb:GetDataObjectByName(DATA_OBJECT_NAME)
	if not dataObject then
		dataObject = ldb:NewDataObject(DATA_OBJECT_NAME, {
			type = "launcher",
			text = ns.title,
			icon = ns.assets.icon,
			OnClick = onClick,
			OnTooltipShow = onTooltipShow,
		})
	end

	self.dbIcon = dbIcon
	self.dataObject = dataObject
	dbIcon:Register(DATA_OBJECT_NAME, dataObject, ns:GetDB().profile.minimap)

	self.initialized = true
end

function MinimapButton:Show()
	ns:GetDB().profile.minimap.hide = false
	if self.dbIcon then
		self.dbIcon:Show(DATA_OBJECT_NAME)
	end
end

function MinimapButton:Hide()
	ns:GetDB().profile.minimap.hide = true
	if self.dbIcon then
		self.dbIcon:Hide(DATA_OBJECT_NAME)
	end
end

function MinimapButton:Toggle()
	if ns:GetDB().profile.minimap.hide then
		self:Show()
	else
		self:Hide()
	end
end
