local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundEffects = ReplicatedStorage.Assets.Sounds.SoundEffects

local PurchaseSound = SoundEffects.Gui.Purchase

local PromptMenu = require(script.PromptMenu)

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local SharedData = require(script.Parent.Data)

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)
local TouchToProduct = require(script.TouchToProduct)
local PromptToProduct = require(script.PromptToProduct)

local Value, New, Children = Fusion.Value, Fusion.New, Fusion.Children
local scoped, peek = Fusion.scoped, Fusion.peek

local MonitizationClient = {
	playerGamepasses = {} :: { [number]: { [string]: Fusion.Value<boolean, any> } },
	data = SharedData,
}
MonitizationClient.getOwnedGamepasses = Net:RemoteFunction("GetOwnedGamepasses")

MonitizationClient.playerGamepassesLoaded = Signal.new()
MonitizationClient.playerPurchasedGamepass = Signal.new()
MonitizationClient.productPurchased = Signal.new()

function MonitizationClient.SetPrompting(id: number): boolean
	if peek(MonitizationClient.promptingId) == -1 then
		MonitizationClient.promptingId:set(id)
		return true
	else
		return false
	end
end

function MonitizationClient.PromptPurchase(id: number): ()
	local key = MonitizationClient.productKeysById[id]
	local data = SharedData.Products[key]
	if
		data.ProductType == "Gamepass"
		and not peek(MonitizationClient.playerGamepasses[Players.LocalPlayer.UserId][key])
	then
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, data.Id)
		MonitizationClient.SetPrompting(id)
	elseif data.ProductType == "Product" then
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, data.Id)
		MonitizationClient.SetPrompting(id)
	end
end

function MonitizationClient.init(): ()
	local scope = scoped(Fusion)
	MonitizationClient.promptingId = Value(scope, -1)
	MonitizationClient.promptGui = New(scope, "ScreenGui")({
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		DisplayOrder = 4,
		Name = "ProductPrompt",
		[Children] = PromptMenu(scope, {
			promptingId = MonitizationClient.promptingId,
		}),
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	}) :: ScreenGui

	MonitizationClient.productKeysById = {} :: { string }
	for i, v in SharedData.Products do
		MonitizationClient.productKeysById[v.Id] = i
	end

	local functionTypes = {}
	for _, v in script.Types:GetChildren() do
		functionTypes[v.Name] = require(v)
	end

	local function handleSuccess()
		Sound.new(PurchaseSound, workspace):Play()
	end

	MonitizationClient.playerGamepasses[Players.LocalPlayer.UserId] = {}
	local function setGamepassOwned(userId: number, key: string, owned: boolean)
		if not MonitizationClient.playerGamepasses[userId] then
			MonitizationClient.playerGamepasses[userId] = {}
		end
		if not MonitizationClient.playerGamepasses[userId][key] then
			MonitizationClient.playerGamepasses[userId][key] = Value(scope, owned)
		else
			MonitizationClient.playerGamepasses[userId][key]:set(owned)
		end
	end

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
		MonitizationClient.promptingId:set(-1)
		if isPurchased then
			handleSuccess()
		end
		MonitizationClient.productPurchased:Fire(
			Players:GetPlayerByUserId(userId),
			MonitizationClient.productKeysById[productId],
			isPurchased
		)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, productId, isPurchased)
		MonitizationClient.promptingId:set(-1)
		if isPurchased then
			handleSuccess()

			local productKey = MonitizationClient.productKeysById[productId]

			setGamepassOwned(tonumber(player.UserId), productKey, true)
			MonitizationClient.playerPurchasedGamepass:Fire(player, productKey)
		end
		MonitizationClient.productPurchased:Fire(player, MonitizationClient.productKeysById[productId], isPurchased)
	end)
	MarketplaceService.PromptPurchaseFinished:Connect(function(userId, productId, isPurchased)
		MonitizationClient.promptingId:set(-1)
		if isPurchased then
			handleSuccess()
		end
		MonitizationClient.productPurchased:Fire(
			Players:GetPlayerByUserId(userId),
			MonitizationClient.productKeysById[productId],
			isPurchased
		)
	end)
	MonitizationClient.productPurchased:Connect(function(player: Player, productKey: string, isPurchased: boolean)
		local productData = SharedData.Products[productKey]
		if productData then
			local clientFunctionTypes = productData.ClientFunctionTypes
			if clientFunctionTypes then
				for i, v in clientFunctionTypes do
					functionTypes[v](i, productKey, productData, isPurchased)
				end
			end
		end
	end)

	local list = MonitizationClient.getOwnedGamepasses:InvokeServer()
	for userId, passes in list do
		for key, owned in passes do
			setGamepassOwned(tonumber(userId), key, owned)
		end
	end
	Net:Connect("GamepassesLoaded", function(userId: string, loadedGamepasses: { [number]: { [string]: boolean } })
		for i, v in loadedGamepasses do
			setGamepassOwned(tonumber(userId), i, v)
		end

		local player = Players:GetPlayerByUserId(userId)
		if player then
			MonitizationClient.playerGamepassesLoaded:Fire(player)
		end
	end)
	Net:Connect("PlayerPurchasedGamepass", function(userId: string, key: string, wasPurchased: boolean)
		if wasPurchased then
			setGamepassOwned(tonumber(userId), key, true)

			local player = Players:GetPlayerByUserId(userId)
			if player then
				MonitizationClient.playerPurchasedGamepass:Fire(player, key)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		MonitizationClient.playerGamepasses[player.UserId] = nil
	end)

	Observers.observeTag("TouchToProduct", function(instance)
		local touchToProduct = TouchToProduct.new(instance)
		touchToProduct._trove:Add(touchToProduct.toucher.PlayerTouched:Connect(function(player: Player)
			local productId = instance:GetAttribute("Id")
			local productKey = MonitizationClient.productKeysById[productId]

			local userdId = player.UserId
			if
				not MonitizationClient.playerGamepasses[userdId]
				or (
					MonitizationClient.playerGamepasses[userdId]
					and not peek(MonitizationClient.playerGamepasses[userdId][productKey])
				)
			then
				MonitizationClient.PromptPurchase(tonumber(productId))
			end
		end))
		return function()
			touchToProduct:Destroy()
		end
	end)
	Observers.observeTag("PromptToProduct", function(instance)
		local promptToProduct = PromptToProduct.new(instance, MonitizationClient.PromptPurchase)
		return function()
			promptToProduct:Destroy()
		end
	end)
end

return MonitizationClient
