local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local RewardServer = require(Services.RewardService.Server)

local SharedData = require(script.Parent.Data)

local Net = require(ReplicatedStorage.Packages.Net)

local getWeightedRandom = require(ReplicatedStorage.Shared.Modules.Utilities.getWeightedRandom)

local rewardWeightData: { [string]: number } = {}

local SpinnerServer = {
	players = {},
}
SpinnerServer.updatePlayerSpins = Net:RemoteEvent("SpinsUpdated")

function SpinnerServer.GivePlayerSpins(player: Player, amount: number)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end
	playerProfile.Data.Spins += amount
	SpinnerServer.updatePlayerSpins:FireClient(player, playerProfile.Data.Spins)
end

function SpinnerServer.SpinAttempt(player: Player): number
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end

	assert(not SpinnerServer.players[player.UserId].spinning, `{player.Name} was already spinning`)
	assert(playerProfile.Data.Spins > 0, `{player.Name} didn't have any spins left`)

	local chosenRewardIndex = (SharedData.Testing.Enabled and SharedData.Testing.GuaranteedReward ~= -1)
			and SharedData.Testing.GuaranteedReward
		or tonumber(getWeightedRandom(rewardWeightData))
	local data = SharedData.Rewards[chosenRewardIndex]
	SpinnerServer.players[player.UserId].spinning = true

	task.delay(SharedData.AwardDelay + 1, function()
		if player.Parent then
			SpinnerServer.players[player.UserId].spinning = false
			playerProfile.Data.Spins -= 1
			RewardServer.AwardPlayer(player, data)
		end
	end)

	local endAngle = ((chosenRewardIndex - 1) * 60) + 30
	local startAngle = endAngle - 60
	return chosenRewardIndex, math.random(startAngle, endAngle)
end

function SpinnerServer.init()
	for i, v in SharedData.Rewards do
		rewardWeightData[tostring(i)] = v.Weight
	end
	local function checkPlayerSpins(player: Player)
		local playerProfile = PlayerDataServer.Profiles[player]
		if playerProfile then
			local today = os.date("%j")
			if today ~= playerProfile.Data.SpinsClaimedDate then
				playerProfile.Data.SpinsClaimedDate = today
				playerProfile.Data.Spins += 1
				SpinnerServer.updatePlayerSpins:FireClient(player, playerProfile.Data.Spins)
			end
		end
	end
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		SpinnerServer.players[player.UserId] = {
			spinning = false,
		}

		local playerProfile = PlayerDataServer.Profiles[player]
		checkPlayerSpins(player)
		SpinnerServer.updatePlayerSpins:FireClient(player, playerProfile.Data.Spins)
	end)
	Players.PlayerRemoving:Connect(function(player)
		SpinnerServer.players[player.UserId] = nil
	end)
	Net:Handle("GetSpins", function(player)
		local playerProfile = PlayerDataServer.Profiles[player]
		if playerProfile then
			return playerProfile.Data.Spins
		end
	end)
	Net:Handle("SpinAttempt", SpinnerServer.SpinAttempt)
	while true do
		for _, v in Players:GetPlayers() do
			checkPlayerSpins(v)
		end
		task.wait(1)
	end
end

return SpinnerServer
