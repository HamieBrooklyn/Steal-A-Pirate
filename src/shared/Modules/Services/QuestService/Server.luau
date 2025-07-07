local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local QuestServer = {}

function QuestServer.init()
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local profile = PlayerDataServer.Profiles[player]
		if profile.SessionLoadCount == 1 then
			player:SetAttribute("IsInTutorial", true)
		end
	end)
end

return QuestServer
