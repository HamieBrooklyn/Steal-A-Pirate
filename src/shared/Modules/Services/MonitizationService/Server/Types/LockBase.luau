local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function LockBase(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	if wasPurchased then
		local base = BaseServer.GetPlayerBase(player)
		if base then
			base:SetLocked(true, data.Durations[1])
		end
	end
end

return LockBase
