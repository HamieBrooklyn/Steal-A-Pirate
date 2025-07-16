local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local Types = require(script.Parent.Parent.Types)

local function Statistic(player: Player, data: Types.CodeData, code: string)
	local rewardedString = "You recieved:"
	local count = 0
	for i, v in data.Statistics do
		count += 1
		rewardedString = `{rewardedString}{count > 1 and ", " or ""} {v} {i}`
		PlayerDataServer.UpdateLeaderstat(player, i, v)
	end
	rewardedString = rewardedString .. "."
	return true, rewardedString
end

return Statistic
