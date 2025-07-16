local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseServer = require(ReplicatedStorage.Shared.Modules.Services.BaseService.Server)

return function(contex, player: Player)
	local base = BaseServer.GetPlayerBase(player)
	if not base then
		return player.Name .. "'s base was not found"
	end
	base:ResetAllPlatforms(true)
	return "Reset " .. player.Name .. "'s platforms successfully"
end
