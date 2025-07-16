local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local peek = Fusion.peek

local TouchToProduct = {}
TouchToProduct.__index = TouchToProduct

type self = {
	toucher: Toucher.Toucher,

	_trove: Trove.Trove,
}

export type TouchToProduct = typeof(setmetatable({} :: self, TouchToProduct))

function TouchToProduct.new(part: BasePart): TouchToProduct
	local self = setmetatable({}, TouchToProduct) :: TouchToProduct

	self._trove = Trove.new()

	self.toucher = self._trove:Add(Toucher.new(part)) :: Toucher.Toucher

	return self
end

function TouchToProduct.Destroy(self: TouchToProduct): ()
	self._trove:Destroy()
end

return TouchToProduct
