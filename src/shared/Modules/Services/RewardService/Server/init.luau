local SharedData = require(script.Parent.Data)

local Rewards = script.Rewards

local SomeReward = require(Rewards.SomeReward)

export type RewardMethod = typeof(SomeReward)

local rewardMethods: { [string]: SomeReward } = {}

local RewardServer = {}

function RewardServer.AwardPlayer(player: Player, data: SharedData.RewardData)
	for _, v in data.Rewards do
		task.spawn(rewardMethods[v], player, data.Values[v])
	end
end

function RewardServer.init()
	for _, v in Rewards:GetChildren() do
		rewardMethods[v.Name] = require(v)
	end
end

return RewardServer
