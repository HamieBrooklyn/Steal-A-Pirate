local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local BuyCharacter = {}
BuyCharacter.__index = BuyCharacter

type self = {
	currentText: Fusion.Value<string, any>,

	_trove: Trove.Trove,
}
export type BuyCharacter = typeof(setmetatable({} :: self, BuyCharacter))

function BuyCharacter.new(currentText: Fusion.Value<string, any>, texts: { [string]: string }, ...): BuyCharacter
	local self = setmetatable({}, BuyCharacter) :: BuyCharacter

	self._trove = Trove.new()

	self.currentText = currentText

	return self
end

function BuyCharacter.Start(self: BuyCharacter, texts: { [string]: string }, ...): ()
	self.currentText:set(texts.Main)
end

function BuyCharacter.Clean(self: BuyCharacter): ()
	self._trove:Destroy()
end

return BuyCharacter
