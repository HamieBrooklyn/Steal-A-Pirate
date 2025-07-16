local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local ToolServer = require(Services.ToolService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function GiveTool(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	if wasPurchased then
		local tools: { [string]: { Amount: number, Permanent: boolean, SaveOnDeath: boolean } } = data.Values[index]
		for i, v in tools do
			ToolServer.GivePlayerTool(player, i, v.Amount, v.SaveOnDeath, v.Permanent)
		end
	end
end

return GiveTool
