local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function Leaderstat(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if wasPurchased and playerProfile then
		for i, v in data.StatNames do
			PlayerDataServer.UpdateLeaderstat(player, v, data.Amounts[i])
		end
	end
end

return Leaderstat
