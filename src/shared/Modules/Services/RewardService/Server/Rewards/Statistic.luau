local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local PopupServer = require(Services.PopupService.Server)
local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

return function(player: Player, statistics: { { Name: string, IsLeaderstat: boolean?, Amount: number } })
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if playerProfile then
		for _, v in statistics do
			if v.IsLeaderstat then
				PlayerDataServer.UpdateLeaderstat(player, v.Name, v.Amount)
			else
				playerProfile.Data[v.Name] += v.Amount
			end
			PopupServer.SendPopupTo(player, {
				message = `You got {abbreviateNumber(v.Amount)} {v.Name}!`,
				gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Apple,
			})
		end
	end
end
