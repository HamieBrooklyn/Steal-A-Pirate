local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SpinnerServer = require(Services.SpinnerService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function Spins(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo)
	if wasPurchased then
		SpinnerServer.GivePlayerSpins(player, data.Amounts[1])
	end
end

return Spins
