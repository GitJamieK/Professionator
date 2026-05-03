local _, ns = ...

local function normalizeCommand(message)
	local command = (message or ""):match("^%s*(%S*)")
	return string.lower(command or "")
end

function ns:RegisterSlashCommands()
	if self.slashCommandsRegistered then
		return
	end

	SLASH_PROFESSIONATOR1 = "/professionator"
	SLASH_PROFESSIONATOR2 = "/prof"

	SlashCmdList.PROFESSIONATOR = function(message)
		local command = normalizeCommand(message)

		if command == "" or command == "toggle" then
			ns.UI:ToggleWindow()
		elseif command == "open" or command == "show" then
			ns.UI:ShowWindow()
		elseif command == "close" or command == "hide" then
			ns.UI:HideWindow()
		elseif command == "minimap" then
			ns.Minimap:Toggle()
		else
			ns:Print("Commands: /professionator, /professionator minimap")
		end
	end

	self.slashCommandsRegistered = true
end
