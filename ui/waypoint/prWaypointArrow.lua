local _, ns = ...

-- A RestedXP/TomTom-style on-screen "crazy arrow" that points toward a trainer and
-- shows the distance in yards. Self-contained: the trainer detail button drives it via
-- Waypoint:Toggle, and it keeps a single arrow frame on UIParent.
local Waypoint = {}
ns.Waypoint = Waypoint

-- HereBeDragons resolves world positions reliably even inside cities, where Blizzard's
-- C_Map.GetWorldPosFromMapPos returns nil. This is the same library RestedXP/TomTom use.
local HBD = LibStub and LibStub("HereBeDragons-2.0", true)

local ARROW_TEXTURE = "Interface\\AddOns\\Professionator\\img\\waypoint\\arrow"
local UPDATE_INTERVAL = 0.05 -- seconds between arrow refreshes
local ARRIVE_DISTANCE = 10 -- yards: treated as "arrived"
local ARRIVE_LINGER = 2 -- seconds the "Arrived!" state shows before auto-clearing

local PI = math.pi
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

-- Placement of each continent on the shared Azeroth world map { width, height, left, top }
-- in yards (from HereBeDragons worldMapData). Only used to approximate cross-continent
-- distance/direction, since per-continent world coordinates aren't directly comparable.
local AZEROTH_WORLD = {
	[0] = { 44688.53, 29795.11, 32601.04, 9894.93 }, -- Eastern Kingdoms
	[1] = { 44878.66, 29916.10, 8723.96, 14824.53 }, -- Kalimdor
}
local AZ_WIDTH = (AZEROTH_WORLD[0][1] + AZEROTH_WORLD[1][1]) / 2
local AZ_HEIGHT = (AZEROTH_WORLD[0][2] + AZEROTH_WORLD[1][2]) / 2

-- Project a continent-local world position onto the shared Azeroth world map (0-1).
local function azerothNorm(worldX, worldY, instance)
	local data = AZEROTH_WORLD[instance]
	if not data then
		return nil
	end
	return (data[3] - worldX) / data[1], (data[4] - worldY) / data[2]
end

local function normalizeAngle(a)
	while a > PI do
		a = a - 2 * PI
	end
	while a < -PI do
		a = a + 2 * PI
	end
	return a
end

-- "34.0, 84.4" -> 0.34, 0.844 (the 0-1 form C_Map expects); nil if unparseable.
local function parseCoords(coords)
	if not coords then
		return nil
	end

	local x, y = coords:match("([%d%.]+)%s*,%s*([%d%.]+)")
	x, y = tonumber(x), tonumber(y)
	if not x or not y then
		return nil
	end

	return x / 100, y / 100
end

local function findTrainer(professionID, factionID, npcID)
	local data = ns.ProfessionData and ns.ProfessionData.trainerData
	if not data or not npcID then
		return nil
	end

	local list = professionID and factionID and data[professionID] and data[professionID][factionID]
	if list then
		for _, trainer in ipairs(list) do
			if trainer.npcID == npcID then
				return trainer
			end
		end
	end

	-- Fallback: the saved profession/faction may not match, so scan everything by npcID.
	for _, byFaction in pairs(data) do
		for _, trainers in pairs(byFaction) do
			for _, trainer in ipairs(trainers) do
				if trainer.npcID == npcID then
					return trainer
				end
			end
		end
	end

	return nil
end

function Waypoint:GetSavedState()
	local profile = ns:GetDB().profile
	local wp = profile.waypoint
	if not wp then
		wp = {}
		profile.waypoint = wp
	end
	return wp
end

function Waypoint:Initialize()
	if self.frame then
		return
	end

	local frame = CreateFrame("Frame", "ProfessionatorWaypointArrow", UIParent)
	frame:SetSize(72, 92)
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetClampedToScreen(true)
	frame:Hide()

	local saved = self:GetSavedState()
	frame:SetPoint(saved.point or "CENTER", UIParent, saved.relativePoint or "CENTER", saved.x or 320, saved.y or -140)

	local warning = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	warning:SetPoint("BOTTOM", frame, "TOP", 0, 4)
	warning:SetWidth(180)
	warning:SetJustifyH("CENTER")
	warning:SetTextColor(1, 0.25, 0.25, 1)
	warning:Hide()

	local arrow = frame:CreateTexture(nil, "ARTWORK")
	arrow:SetTexture(ARROW_TEXTURE)
	arrow:SetSize(48, 48)
	arrow:SetPoint("TOP", frame, "TOP", 0, 0)

	local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("TOP", arrow, "BOTTOM", 0, -4)
	name:SetWidth(140)
	name:SetJustifyH("CENTER")
	name:SetTextColor(1, 0.93, 0.66, 1)

	local distance = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	distance:SetPoint("TOP", name, "BOTTOM", 0, -1)
	distance:SetJustifyH("CENTER")

	frame:SetScript("OnDragStart", function(f)
		f:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		Waypoint:SavePosition()
	end)
	frame:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then
			Waypoint:Clear()
		end
	end)

	self.frame = frame
	self.arrow = arrow
	self.warningText = warning
	self.nameText = name
	self.distanceText = distance
end

function Waypoint:SavePosition()
	if not self.frame then
		return
	end

	local point, _, relativePoint, x, y = self.frame:GetPoint()
	local saved = self:GetSavedState()
	saved.point = point
	saved.relativePoint = relativePoint
	saved.x = x
	saved.y = y
end

function Waypoint:IsActiveFor(trainer)
	if not self.active or not self.target or not trainer then
		return false
	end

	return trainer.npcID ~= nil and trainer.npcID == self.target.npcID
end

function Waypoint:Toggle(trainer, professionID, factionID)
	if not trainer then
		return
	end

	if self:IsActiveFor(trainer) then
		self:Clear()
	else
		self:SetTarget(trainer, professionID, factionID)
	end
end

function Waypoint:SetTarget(trainer, professionID, factionID)
	if not trainer then
		return
	end

	self:Initialize()

	local mapID = ns.ZoneData.GetMapID(trainer.zone)
	local x, y = parseCoords(trainer.coords)
	if not mapID or not x or not y then
		ns:Print("No map data available for " .. (trainer.name or "this trainer") .. "'s location.")
		return
	end

	-- Safety net: if the configured uiMapID can't be resolved on this client, say which
	-- one so a wrong map id is obvious instead of silently showing "-- yd".
	if HBD and not HBD:GetWorldCoordinatesFromZone(x, y, mapID) then
		ns:Print(("Waypoint: couldn't resolve map %s (%s) on this client."):format(tostring(mapID), tostring(trainer.zone)))
	end

	self.active = true
	self.arrived = false
	self.target = {
		mapID = mapID,
		x = x,
		y = y,
		name = trainer.name or "Trainer",
		npcID = trainer.npcID,
	}

	-- Persist so the waypoint survives a /reload; prEvents clears this on a fresh login.
	local saved = self:GetSavedState()
	saved.active = true
	saved.target = {
		professionID = professionID,
		factionID = factionID,
		npcID = trainer.npcID,
	}

	-- Flag opposite-faction trainers so the player notices before trekking there.
	local playerFaction = UnitFactionGroup("player")
	if factionID and playerFaction and factionID ~= string.lower(playerFaction) then
		self.warningText:SetText("Opposite Faction!")
		self.warningText:Show()
	else
		self.warningText:Hide()
	end

	self.nameText:SetText(self.target.name)
	self.frame:Show()
	self:SetWorldMapPin()
	self:StartUpdating()
	self:NotifyButton()
end

function Waypoint:Clear()
	self.active = false
	self.arrived = false
	self.target = nil

	self:StopUpdating()
	if self.frame then
		self.frame:Hide()
	end

	local saved = self:GetSavedState()
	saved.active = false
	saved.target = nil

	if C_Map and C_Map.ClearUserWaypoint then
		C_Map.ClearUserWaypoint()
	end

	self:NotifyButton()
end

function Waypoint:RestoreFromDB()
	local saved = self:GetSavedState()
	if not saved.active or not saved.target then
		return
	end

	local target = saved.target
	local trainer = findTrainer(target.professionID, target.factionID, target.npcID)
	if not trainer then
		saved.active = false
		saved.target = nil
		return
	end

	self:SetTarget(trainer, target.professionID, target.factionID)
end

-- Mirror the active waypoint onto Blizzard's world map + minimap.
function Waypoint:SetWorldMapPin()
	local target = self.target
	if not target or not C_Map then
		return
	end

	if C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(target.mapID) and UiMapPoint then
		C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(target.mapID, target.x, target.y))
		if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
			C_SuperTrack.SetSuperTrackedUserWaypoint(true)
		end
	end
end

-- Refresh the trainer detail waypoint button (active/inactive) if it is on screen.
function Waypoint:NotifyButton()
	local menu = ns.ProfessionMenu
	if menu and menu.RefreshWaypointButton then
		menu:RefreshWaypointButton()
	end
end

function Waypoint:StartUpdating()
	if not self.frame then
		return
	end

	local elapsed = 0
	self.frame:SetScript("OnUpdate", function(_, dt)
		elapsed = elapsed + dt
		if elapsed < UPDATE_INTERVAL then
			return
		end
		elapsed = 0
		Waypoint:UpdateArrow()
	end)
	self:UpdateArrow()
end

function Waypoint:StopUpdating()
	if self.frame then
		self.frame:SetScript("OnUpdate", nil)
	end
end

function Waypoint:OnArrived()
	if self.arrived then
		return
	end
	self.arrived = true

	self.arrow:SetRotation(0)
	self.arrow:SetVertexColor(0.2, 1, 0.2)
	self.arrow:SetAlpha(1)
	self.distanceText:SetText("Arrived!")
	self.distanceText:SetTextColor(0.4, 1, 0.4)

	self:StopUpdating()
	C_Timer.After(ARRIVE_LINGER, function()
		if Waypoint.arrived then
			Waypoint:Clear()
		end
	end)
end

function Waypoint:UpdateArrow()
	local target = self.target
	if not target then
		return
	end

	-- World coordinates (in yards) via HereBeDragons. HBD x = north axis, y = west axis,
	-- and works inside cities where C_Map.GetWorldPosFromMapPos returns nil.
	local playerX, playerY, playerInstance, targetX, targetY, targetInstance
	if HBD then
		playerX, playerY, playerInstance = HBD:GetPlayerWorldPosition()
		targetX, targetY, targetInstance = HBD:GetWorldCoordinatesFromZone(target.x, target.y, target.mapID)
	end

	-- Positions not resolvable yet (data still loading): keep the arrow up and show a
	-- placeholder rather than hiding the distance.
	if not playerX or not targetX then
		self.arrow:SetRotation(0)
		self.arrow:SetVertexColor(0.75, 0.75, 0.75)
		self.arrow:SetAlpha(0.6)
		self.distanceText:SetText("-- yd")
		self.distanceText:SetTextColor(0.85, 0.85, 0.85)
		return
	end

	local dNorth, dWest, crossContinent
	if playerInstance == targetInstance then
		dNorth = targetX - playerX
		dWest = targetY - playerY
	else
		-- Different continents: project both points onto the shared Azeroth world map for
		-- an approximate over-the-sea straight-line distance and direction.
		local pnx, pny = azerothNorm(playerX, playerY, playerInstance)
		local tnx, tny = azerothNorm(targetX, targetY, targetInstance)
		if not pnx or not tnx then
			self.arrow:SetRotation(0)
			self.arrow:SetVertexColor(0.75, 0.75, 0.75)
			self.arrow:SetAlpha(0.6)
			self.distanceText:SetText("-- yd")
			self.distanceText:SetTextColor(0.85, 0.85, 0.85)
			return
		end
		crossContinent = true
		dNorth = -AZ_WIDTH * (tnx - pnx)
		dWest = -AZ_HEIGHT * (tny - pny)
	end

	local dist = math.sqrt(dNorth * dNorth + dWest * dWest)

	-- Always show the distance so the player knows how far they are.
	self.distanceText:SetText(string.format("%d yd", math.floor(dist + 0.5)))
	self.distanceText:SetTextColor(1, 0.82, 0)

	if dist <= ARRIVE_DISTANCE and not crossContinent then
		self:OnArrived()
		return
	end

	-- Angle from the player's facing to the target (0 = dead ahead).
	-- Bearing is measured counter-clockwise from north, matching GetPlayerFacing.
	local facing = GetPlayerFacing() or 0
	local rel = normalizeAngle(atan2(dWest, dNorth) - facing)
	self.arrow:SetRotation(rel) -- if mirrored in-game, flip to -rel

	-- Tint green (dead ahead) -> yellow -> red (behind you).
	local t = math.abs(rel) / PI
	self.arrow:SetVertexColor(math.min(1, 2 * t), math.min(1, 2 * (1 - t)), 0)
	self.arrow:SetAlpha(1)
end
