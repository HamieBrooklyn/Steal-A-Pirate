local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SpawningServer = require(Services.SpawningService.Server)
local BaseServer = require(Services.BaseService.Server)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

return function(context, player: Player, pirateName: string, amount: number?)
	amount = amount or 1
	local base = BaseServer.GetPlayerBase(player)
	if base then
		for _ = 1, amount do
			if not peek(base.BaseFull) then
				BaseServer.GivePlayerCharacter(player, pirateName)
			else
				SpawningServer.AddCachedSpawnForPlayer(player, pirateName)
				return `{player}'s base was full, {pirateName} was put in their cached pirates`
			end
		end
	else
		return `{player} didnt have a base set`
	end
end
