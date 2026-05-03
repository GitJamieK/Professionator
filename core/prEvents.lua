local ADDON_NAME, ns = ...

local eventFrame = CreateFrame("Frame")
ns.EventFrame = eventFrame

local function initializeAddon()
	if ns.initialized then
		return
	end

	ns:ApplyDefaults()
	ns.UI:Initialize()
	ns.Minimap:Initialize()
	ns:RegisterSlashCommands()

	ns.initialized = true
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event ~= "ADDON_LOADED" then
		return
	end

	local loadedAddonName = ...
	if loadedAddonName ~= ADDON_NAME then
		return
	end

	initializeAddon()
	self:UnregisterEvent("ADDON_LOADED")
end)
