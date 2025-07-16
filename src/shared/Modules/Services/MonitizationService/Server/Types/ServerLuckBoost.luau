local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SpawningServer = require(Services.SpawningService.Server)
local PopupServer = require(Services.PopupService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

local function ServerLuckBoost(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	if wasPurchased then
		for i, v in data.Portals do
			SpawningServer.spawners[SpawningServer.portalNamesById[v]]:ActivateLuckBoost(
				data.Amounts[i],
				data.Durations[i]
			)
			PopupServer.SendServerPopup({
				message = `A {data.Amounts[i]}X Luck boost has started for {formatTime(data.Durations[i], {
					mode = "text",
				})} at {v}`,
				duration = 5,
				gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Apple,
			})
		end
	end
end

return ServerLuckBoost
