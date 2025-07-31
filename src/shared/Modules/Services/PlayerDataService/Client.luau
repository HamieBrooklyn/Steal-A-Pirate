local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Net = require(ReplicatedStorage.Packages.Net)

local scoped = Fusion.scoped

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
	local scope = scoped(Fusion)

	PlayerDataClient.loaded = false

	local function check()
		local leaderstats: Folder = Players.LocalPlayer:WaitForChild("leaderstats")

		observeChildren(leaderstats, function(value: ValueBase?)
			if not value:IsA("ValueBase") then
				return
			end

			PlayerDataClient.leaderstats[value.Name] = scope:Value(value.Value)
			local cleanup = Observers.observeProperty(value, "Value", function(newValue: any)
				PlayerDataClient.leaderstats[value.Name]:set(newValue)
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
