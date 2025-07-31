local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local IndexServer = require(Services.IndexService.Server)

local SharedSpawningData = require(Services.SpawningService.Data)

return function(context, player: Player)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if playerProfile then
		local unlocked = {}
		for i, v in SharedSpawningData.Characters.Info do
			if v.Natural == false then
				continue
			end
			if not table.find(playerProfile.Data.UnlockedCharacters, i) then
				table.insert(playerProfile.Data.UnlockedCharacters, i)
				table.insert(unlocked, i)
			end
		end
		IndexServer.unlockedNewCharacters:FireClient(player, unlocked)
	end
end
