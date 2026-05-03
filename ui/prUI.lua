local _, ns = ...

local UI = {}
ns.UI = UI

function UI:Initialize()
	if ns.Window then
		ns.Window:Create()
	end
end

function UI:GetWindow()
	return ns.Window and ns.Window:GetFrame() or nil
end

function UI:ShowWindow()
	if ns.Window then
		ns.Window:Show()
	end
end

function UI:HideWindow()
	if ns.Window then
		ns.Window:Hide()
	end
end

function UI:ToggleWindow()
	if ns.Window then
		ns.Window:Toggle()
	end
end
