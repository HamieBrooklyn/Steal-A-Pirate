local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)

local Base = require(Services.BaseService.Server.Base)

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function UnlockBase(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	if wasPurchased then
		local char = player.Character
		if not char then
			return
		end
		local closestM = math.huge
		local closestBase: Base.Base
		for _, v in BaseServer.Bases do
			local m = (v.Model:GetPivot().Position - char:GetPivot().Position).Magnitude
			if m < closestM then
				closestM = m
				closestBase = v
			end
		end
		closestBase:SetLocked(false)
	end
end

return UnlockBase
