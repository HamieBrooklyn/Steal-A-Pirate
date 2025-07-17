local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FunctionTypes = script.Types

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)

local SomeProductType = require(FunctionTypes.SomeProductType)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)
local FloatingItem = require(script.FloatingItem)

export type SharedTypes = typeof(SharedTypes)
export type FunctionType = typeof(SomeProductType)

local MonitizationServer = {
	data = SharedData,
	playerGamepasses = {} :: { [number]: { [string]: boolean } },
}
MonitizationServer.gamepassesLoaded = Net:RemoteEvent("GamepassesLoaded")
MonitizationServer.playerPurchasedGamepass = Net:RemoteEvent("PlayerPurchasedGamepass")

MonitizationServer.productPurchased = Signal.new()
MonitizationServer.ownedGamepassLoaded = Signal.new()

function MonitizationServer.PlayerOwnsGamepass(player: Player, key: string)
	return Promise.new(function(resolve)
		if MonitizationServer.playerGamepasses[player.UserId][key] ~= nil then
			resolve(MonitizationServer.playerGamepasses[player.UserId][key])
			return
		end
		local loadedCon: RBXScriptConnection
		loadedCon = MonitizationServer.ownedGamepassLoaded:Connect(function(loadedPlayer: Player, loadedKey: string)
			if loadedPlayer == player and loadedKey == key then
				loadedCon:Disconnect()
				resolve(MonitizationServer.playerGamepasses[player.UserId][key])
			end
		end)
	end)
end

function MonitizationServer.ProductPurchased(player: Player, key: string, wasPurchased: boolean)
	local productData = SharedData.Products[key]
	if productData then
		local functionTypes = productData.ServerFunctionTypes
		if functionTypes then
			for i, v in functionTypes do
				if MonitizationServer.productFunctionTypes[v] then
					MonitizationServer.productFunctionTypes[v](player, wasPurchased, productData, i)
				end
			end
		end
		if productData.ProductType == "Gamepass" then
			if wasPurchased then
				MonitizationServer.playerGamepasses[player.UserId][key] = true
			end
			MonitizationServer.playerPurchasedGamepass:FireAllClients(tostring(player.UserId), key, wasPurchased)
		end
	end

	MonitizationServer.productPurchased:Fire(player, wasPurchased, key, productData)
end

function MonitizationServer.init()
	Players.PlayerAdded:Connect(function(player)
		MonitizationServer.playerGamepasses[player.UserId] = {}
		for i, v in SharedData.Products do
			if v.ProductType == "Gamepass" then
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, v.Id)
				end)
				if MonitizationServer.playerGamepasses[player.UserId] then
					MonitizationServer.playerGamepasses[player.UserId][i] = if success then owns else false
				else
					break
				end
				if not success then
					warn(owns)
				else
					MonitizationServer.ownedGamepassLoaded:Fire(player, i)
				end
			end
		end
		if player.Parent then
			MonitizationServer.gamepassesLoaded:FireAllClients(
				tostring(player.UserId),
				MonitizationServer.playerGamepasses[player.UserId]
			)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		MonitizationServer.playerGamepasses[player.UserId] = nil
	end)
	Net:Handle("GetOwnedGamepasses", function()
		return MonitizationServer.playerGamepasses
	end)

	MonitizationServer.productKeysById = {} :: { string }
	for i, v in SharedData.Products do
		MonitizationServer.productKeysById[v.Id] = i
	end

	MonitizationServer.productFunctionTypes = {} :: { FunctionType }
	for _, functionTypeMod: ModuleScript? in FunctionTypes:GetChildren() do
		if functionTypeMod:IsA("ModuleScript") then
			MonitizationServer.productFunctionTypes[functionTypeMod.Name] = require(functionTypeMod)
		end
	end

	local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")
	MarketplaceService.ProcessReceipt = function(receiptInfo: SharedTypes.RecieptInfo)
		local success, result = pcall(
			purchaseHistoryStore.UpdateAsync,
			purchaseHistoryStore,
			receiptInfo.PurchaseId,
			function(isPurchased)
				if isPurchased then
					return true
				end

				local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
				if not player then
					return nil
				end

				MonitizationServer.ProductPurchased(
					Players:GetPlayerByUserId(receiptInfo.PlayerId),
					MonitizationServer.productKeysById[receiptInfo.ProductId],
					isPurchased
				)

				return true
			end
		)

		if not success then
			local errorMessage = result
			warn(`Failed to process receipt due to data store error: {errorMessage}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local didGrantPurchase = result == true
		return if didGrantPurchase
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		MonitizationServer.ProductPurchased(player, MonitizationServer.productKeysById[gamePassId], wasPurchased)
	end)

	Observers.observeTag("Floating", function(instance)
		local floatingItem = FloatingItem.new(instance)
		return function()
			floatingItem:Destroy()
		end
	end)
end

return MonitizationServer
