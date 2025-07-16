local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function Character(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	local base = BaseServer.GetPlayerBase(player)
	if base then
		for _, v in data.CharacterNames do
			base:AddCharacter(player, v)
		end
	end
end

return Character
