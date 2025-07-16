local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataServer = require(ReplicatedStorage.Shared.Modules.Services.PlayerDataService.Server)

return function(context, player: Player, statName: string, newValue: any)
	local val = player:WaitForChild("leaderstats"):FindFirstChild(statName)
	if val then
		PlayerDataServer.SetLeaderstat(player, statName, newValue)
	else
		return statName .. " was not a stat found anywhere inside " .. " " .. player.Name .. "'s leaderstats"
	end
	return player.Name .. "'s " .. " " .. statName .. " was set to " .. " " .. newValue
end
