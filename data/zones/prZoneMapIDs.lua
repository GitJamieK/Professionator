local _, ns = ...

-- Maps the zone strings used in trainer data (trainer.zone) to the uiMapID that
-- C_Map.* expects. The waypoint arrow resolves a trainer's location through this
-- table, so every zone referenced by a trainer must appear here.
--
-- IMPORTANT: WoW Classic Era uses its own contiguous uiMapID block (1411-1458) for
-- the original zones and capitals, NOT the retail ids (Elwynn 37, Ironforge 87, ...).
-- Retail ids return nil from the position APIs on this client. Values verified against
-- the Classic Era UiMap DB2 (wago.tools); Ironforge = 1455 also confirmed in-game.
local ZoneData = {}
ns.ZoneData = ZoneData

local MAP_IDS = {
	["Durotar"] = 1411,
	["Mulgore"] = 1412,
	["Arathi Highlands"] = 1417,
	["Tirisfal Glades"] = 1420,
	["Dun Morogh"] = 1426,
	["Elwynn Forest"] = 1429,
	["Wetlands"] = 1437,
	["Teldrassil"] = 1438,
	["Dustwallow Marsh"] = 1445,
	["Stormwind City"] = 1453,
	["Orgrimmar"] = 1454,
	["Ironforge"] = 1455,
	["Thunder Bluff"] = 1456,
	["Darnassus"] = 1457,
	["Undercity"] = 1458,
}

-- Returns the uiMapID for a zone name, or nil when the zone is not mapped yet.
function ZoneData.GetMapID(zoneName)
	if not zoneName then
		return nil
	end

	return MAP_IDS[zoneName]
end
