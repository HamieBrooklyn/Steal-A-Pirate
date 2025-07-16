local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local MonitizationServer = require(Services.MonitizationService.Server)

local SharedMonitizationData = require(Services.MonitizationService.Data)

return function(context, player: Player)
	for i, v in SharedMonitizationData.Products do
		if v.ProductType == "Gamepass" then
			MonitizationServer.ProductPurchased(player, i, true)
		end
	end
end
