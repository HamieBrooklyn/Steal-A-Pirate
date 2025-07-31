local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FriendBoostLabel = require(script.FriendBoostLabel)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Net = require(ReplicatedStorage.Packages.Net)

local atom = Charm.atom

local PlayerClient = {
	friendBoostMult = atom(1),
}
PlayerClient.getFriendBoost = Net:RemoteFunction("GetFriendBoost")

function PlayerClient.init()
	require(script.Stealing).new()

	PlayerClient.friendBoostMult(PlayerClient.getFriendBoost:InvokeServer())
	Net:Connect("FriendBoostUpdated", function(newFriendBoost: number)
		PlayerClient.friendBoostMult(newFriendBoost)
	end)
	Charm.subscribe(PlayerClient.friendBoostMult, function(state, prev) end)

	Observers.observeTag("FriendBoostLabel", function(label)
		local class = FriendBoostLabel.new(label, PlayerClient.friendBoostMult)
		return function()
			class:Destroy()
		end
	end)
end

return PlayerClient
