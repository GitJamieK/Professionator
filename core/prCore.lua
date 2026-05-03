local ADDON_NAME, ns = ...

ns.name = ADDON_NAME
ns.title = "Professionator"
ns.author = "Jemi"
ns.version = "0.1.0"

ns.assets = {
	icon = "Interface\\AddOns\\Professionator\\img\\icon\\professionatoricon.tga",
	iconSource = "img\\icon\\professionatoricon.png",
}

ns.defaults = {
	profile = {
		minimap = {
			hide = false,
			minimapPos = 220,
			radius = 80,
		},
		window = {
			point = "CENTER",
			relativePoint = "CENTER",
			x = 0,
			y = 0,
		},
	},
}

local function copyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end

			copyDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

function ns:ApplyDefaults()
	ProfessionatorDB = ProfessionatorDB or {}
	copyDefaults(ProfessionatorDB, self.defaults)
	self.db = ProfessionatorDB

	return self.db
end

function ns:GetDB()
	return self.db or self:ApplyDefaults()
end

function ns:GetBackdropTemplate()
	return BackdropTemplateMixin and "BackdropTemplate" or nil
end

function ns:GetMetadata(field)
	local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	if getMetadata then
		return getMetadata(self.name, field)
	end
end

function ns:Print(message)
	if DEFAULT_CHAT_FRAME and message then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Professionator:|r " .. tostring(message))
	end
end
