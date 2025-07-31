local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local TouchToProduct = {}
TouchToProduct.__index = TouchToProduct

type self = {
	_trove: Trove.Trove,
}

export type TouchToProduct = typeof(setmetatable({} :: self, TouchToProduct))

function TouchToProduct.new(part: BasePart, touch: () -> ()): TouchToProduct
	local self = setmetatable({}, TouchToProduct) :: TouchToProduct

	self._trove = Trove.new()

	self._trove:Add(part.Touched:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if player and player == Players.LocalPlayer then
			touch(player)
		end
	end))

	return self
end

function TouchToProduct.Destroy(self: TouchToProduct): ()
	self._trove:Destroy()
end

return TouchToProduct
