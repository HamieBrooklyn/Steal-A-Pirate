local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GlobalLeaderboard = require(script.GlobalLeaderboard)

local SharedData = require(script.Parent.Data)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Net = require(ReplicatedStorage.Packages.Net)

local GlobalLeaderboardServer = {
	globalLeaderboards = {} :: { GlobalLeaderboard.GlobalLeaderboard },
	globalLeaderboardsCount = 0,
}
GlobalLeaderboardServer.globalLeaderboardUpdated = Net:RemoteEvent("GlobalLeaderboardUpdated")

function GlobalLeaderboardServer.init()
	Observers.observeTag("GlobalLeaderboard", function(instance)
		local globalLeaderboard = GlobalLeaderboard.new(instance)
		GlobalLeaderboardServer.globalLeaderboards[instance] = globalLeaderboard
		GlobalLeaderboardServer.globalLeaderboardsCount += 1
		return function()
			GlobalLeaderboardServer.globalLeaderboards[instance] = nil
			GlobalLeaderboardServer.globalLeaderboardsCount -= 1
			globalLeaderboard:Destroy()
		end
	end)
	Net:Handle("GetGlobalLeaderboardLists", function()
		local listedData = {}
		for _, v in GlobalLeaderboardServer.globalLeaderboards do
			if #v.lastList > 0 then
				listedData[v.id] = v.lastList
			end
		end
		return listedData
	end)

	local lastUpdate = 0
	RunService.Heartbeat:Connect(function()
		if time() - lastUpdate > SharedData.UpdateInterval then
			lastUpdate = time()
			for _, v in GlobalLeaderboardServer.globalLeaderboards do
				v:Update(function(list)
					GlobalLeaderboardServer.globalLeaderboardUpdated:FireAllClients(v.id, list)
				end)
				--task.wait(SharedData.UpdateInterval / GlobalLeaderboardServer.globalLeaderboardsCount)
			end
		end
	end)
end

return GlobalLeaderboardServer
