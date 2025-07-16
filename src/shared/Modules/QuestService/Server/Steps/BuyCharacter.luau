local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local BuyCharacter = {}
BuyCharacter.__index = BuyCharacter

type self = {
	_trove: Trove.Trove,
}
export type BuyCharacter = typeof(setmetatable({} :: self, BuyCharacter))

function BuyCharacter.new(player: Player, texts: { [string]: string }, ...): BuyCharacter
	local self = setmetatable({}, BuyCharacter) :: BuyCharacter

	self._trove = Trove.new()

	return self
end

function BuyCharacter.Start(
	self: BuyCharacter,
	finished: () -> (),
	player: Player,
	texts: { [string]: string },
	...
): ()
end

function BuyCharacter.Clean(self: BuyCharacter): ()
	self._trove:Destroy()
end

return BuyCharacter
