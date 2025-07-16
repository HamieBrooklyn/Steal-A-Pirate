local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local MonitizationServer = require(Services.MonitizationService.Server)

local SharedMonitizationTypes = require(Services.MonitizationService.Types)

local ShopServer = {}

function ShopServer.init()
	-- MonitizationServer.productPurchased:Connect(
	-- 	function(
	-- 		player: Player,
	-- 		wasPurchased: boolean,
	-- 		key: string,
	-- 		productData: SharedMonitizationTypes.ProductInfo
	-- 	)
	-- 		if not productData or not productData. then
	-- 			return
	-- 		end

	-- 	end
	-- )
end

return ShopServer
