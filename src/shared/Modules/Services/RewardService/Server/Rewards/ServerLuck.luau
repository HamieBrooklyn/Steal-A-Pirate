local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SpawningServer = require(Services.SpawningService.Server)
local PopupServer = require(Services.PopupService.Server)

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

return function(player: Player, data: { Mult: number, Duration: number })
	for _, v in SpawningServer.spawners do
		v:ActivateLuckBoost(data.Mult, data.Duration)
		PopupServer.SendServerPopup({
			message = `{player.Name} started a {data.Mult}X Luck boost for {formatTime(
				data.Duration,
				{ mode = "text" }
			)} at {v.Folder.Name}`,
			duration = 5,
			gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Apple,
		})
	end
end
