local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local MonitizationClient = require(Services.MonitizationService.Client)
local PlayerClient = require(Services.PlayerService.Client)

local SharedRebirthsData = require(Services.RebirthService.Data)

local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Net = require(ReplicatedStorage.Packages.Net)

local scoped = Fusion.scoped

local scope = scoped(Fusion)

local PlayerDataClient = {
	leaderstats = {} :: {
		Cash: Fusion.Value<number, any>,
		Rebirths: Fusion.Value<number, any>,
	},
}
PlayerDataClient.LeaderstatsLoaded = Signal.new()

PlayerDataClient.getFirstSessionTime = Net:RemoteFunction("GetFirstSessionTime")
PlayerDataClient.getRedeemedCodes = Net:RemoteFunction("GetRedeemedCodes")

function PlayerDataClient.init()
	PlayerDataClient.loaded = false

	PlayerDataClient.cashMultiplier = scope:Computed(function(use)
		local mult = 0

		mult += SharedRebirthsData.Constants.CashMultiplier * use(PlayerDataClient.leaderstats.Rebirths)
		mult += PlayerClient.friendBoostMult() - 1

		if use(MonitizationClient.playerGamepasses[MonitizationClient.data.Products["2XMoney"]]) == true then
			mult *= 2
		end

		if mult < 1 then
			mult += 1
		end

		return mult
	end)

	local function check()
		local leaderstats: Folder = Players.LocalPlayer:WaitForChild("leaderstats")

		observeChildren(leaderstats, function(value: ValueBase?)
			if not value:IsA("ValueBase") then
				return
			end

			PlayerDataClient.leaderstats[value.Name] = scope:Value(value.Value)
			local cleanup = Observers.observeProperty(value, "Value", function(newValue: any)
				PlayerDataClient.leaderstats[value.Name]:set(newValue)
				print(newValue)
			end)
			return function()
				cleanup()
			end
		end)

		PlayerDataClient.LeaderstatsLoaded:Fire()
		PlayerDataClient.loaded = true
	end
	if Players.LocalPlayer:GetAttribute("ProfileLoaded") then
		check()
	end
	Net:Connect("ProfileLoaded", check)
end

return PlayerDataClient
