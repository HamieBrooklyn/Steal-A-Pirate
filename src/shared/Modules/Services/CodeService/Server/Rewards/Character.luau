local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)

local Types = require(script.Parent.Parent.Types)

local function Character(player: Player, data: Types.CodeData, code: string)
	local base = BaseServer.GetPlayerBase(player)
	base:AddCharacter(player, data.CharacterName)
	return true, "A " .. data.CharacterName .. " spawned in your base!"
end

return Character
