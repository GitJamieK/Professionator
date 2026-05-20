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
	if ns.Waypoint then
		ns.Waypoint:Initialize()
	end
	ns:RegisterSlashCommands()

	ns.initialized = true
end

-- An active waypoint should survive a /reload but not a relog. PLAYER_ENTERING_WORLD's
-- isInitialLogin/isReload flags let us tell the two apart.
local function handlePlayerEnteringWorld(isInitialLogin, isReload)
	if not ns.Waypoint then
		return
	end

	local saved = ns.Waypoint:GetSavedState()
	if isInitialLogin then
		saved.active = false
		saved.target = nil
	elseif isReload then
		ns.Waypoint:RestoreFromDB()
	end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local loadedAddonName = ...
		if loadedAddonName ~= ADDON_NAME then
			return
		end

		initializeAddon()
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReload = ...
		handlePlayerEnteringWorld(isInitialLogin, isReload)
	end
end)
