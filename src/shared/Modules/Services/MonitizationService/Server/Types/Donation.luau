local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function Donation(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if wasPurchased and playerProfile then
		for _, v in data.Amounts do
			playerProfile.Data.TotalDonations += v
		end
	end
end

return Donation
