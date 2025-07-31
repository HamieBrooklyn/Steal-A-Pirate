local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PopupServer = require(Services.PopupService.Server)
local BaseServer = require(Services.BaseService.Server)

return function(player: Player, characters: { string })
	for _, v in characters do
		BaseServer.GivePlayerCharacter(player, v)
		PopupServer.SendPopupTo(player, {
			message = `You got rewarded {v}!`,
			gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.CandyCorn,
		})
		task.wait(0.5)
	end
end
