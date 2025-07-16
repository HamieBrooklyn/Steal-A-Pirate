local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)

local Types = require(script.Parent.Parent.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

local function Character(player: Player, data: Types.CodeData, code: string)
	local base = BaseServer.GetPlayerBase(player)
	if not base then
		return false, "Could not find your base, try waiting or rejoining."
	end

	local freePlatformFound = false
	for _, v in base.Platforms do
		if not peek(v.CharacterName) then
			freePlatformFound = true
		end
	end
	if not freePlatformFound then
		return false, "Your base is full"
	end

	return true
end

return Character
