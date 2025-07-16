local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DonationLeaderboard = require(script.DonationLeaderboard)
local GlobalLeaderboard = require(script.GlobalLeaderboard)
local SharedTypes = require(script.Parent.Types)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Net = require(ReplicatedStorage.Packages.Net)

local GlobalLeaderboardClient = {
	globalLeaderboards = {} :: { GlobalLeaderboard.GlobalLeaderboard },
}
GlobalLeaderboardClient.getGlobalLeaderboardLists = Net:RemoteFunction("GetGlobalLeaderboardLists")

function GlobalLeaderboardClient.init()
	local updateListQueue: { [string]: { SharedTypes.ListItem } } = {}

	Observers.observeTag("GlobalLeaderboard", function(instance)
		local globalLeaderboard = GlobalLeaderboard.new(instance)
		GlobalLeaderboardClient.globalLeaderboards[globalLeaderboard.id] = globalLeaderboard

		globalLeaderboard.listedRanks:set(updateListQueue[globalLeaderboard.id] or {})

		return function()
			GlobalLeaderboardClient.globalLeaderboards[globalLeaderboard.id] = nil
			updateListQueue[globalLeaderboard.id] = nil
			globalLeaderboard:Destroy()
		end
	end)
	Observers.observeTag("DonationLeaderboard", function(instance)
		local donoLeaderboard = DonationLeaderboard.new(instance)
		return function()
			donoLeaderboard:Destroy()
		end
	end)

	Net:Connect("GlobalLeaderboardUpdated", function(id: string, list: { SharedTypes.ListItem })
		if GlobalLeaderboardClient.globalLeaderboards[id] then
			GlobalLeaderboardClient.globalLeaderboards[id].listedRanks:set(list)
		else
			updateListQueue[id] = list
		end
	end)
	local listedGlobalLeaderboards: { [string]: { SharedTypes.ListItem } } =
		GlobalLeaderboardClient.getGlobalLeaderboardLists:InvokeServer()
	for i, v in listedGlobalLeaderboards do
		if GlobalLeaderboardClient.globalLeaderboards[i] then
			GlobalLeaderboardClient.globalLeaderboards[i].listedRanks:set(v)
		else
			updateListQueue[i] = v
		end
	end
end

return GlobalLeaderboardClient
