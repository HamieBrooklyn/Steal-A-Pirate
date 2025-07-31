local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ReplicatedStorage.Shared.Modules.Services

local GlobalLeaderboardServer = require(Services.GlobalLeaderboardService.Server)

return function(context)
	for _, v in GlobalLeaderboardServer.globalLeaderboards do
		GlobalLeaderboardServer.globalLeaderboardUpdated:FireAllClients(v.id, v:Update())
		task.wait(3)
	end
end
