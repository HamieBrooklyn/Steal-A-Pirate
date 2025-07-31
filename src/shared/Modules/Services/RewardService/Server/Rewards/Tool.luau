local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local ToolServer = require(Services.ToolService.Server)
local PopupServer = require(Services.PopupService.Server)

return function(player: Player, toolNames: { string })
	for _, v in toolNames do
		ToolServer.GivePlayerTool(player, v, true, true)
		PopupServer.SendPopupTo(player, {
			message = `You unlocked {v}! Go to the shop to equip it`,
			gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Banana,
		})
	end
end
