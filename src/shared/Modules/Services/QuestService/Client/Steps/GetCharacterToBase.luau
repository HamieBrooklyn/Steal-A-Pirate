local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local GetCharacterToBase = {}
GetCharacterToBase.__index = GetCharacterToBase

type self = {
	currentText: Fusion.Value<string, any>,

	_trove: Trove.Trove,
}
export type GetCharacterToBase = typeof(setmetatable({} :: self, GetCharacterToBase))

function GetCharacterToBase.new(
	currentText: Fusion.Value<string, any>,
	texts: { [string]: string },
	...
): GetCharacterToBase
	local self = setmetatable({}, GetCharacterToBase) :: GetCharacterToBase

	self._trove = Trove.new()

	self.currentText = currentText

	return self
end

function GetCharacterToBase.Start(self: GetCharacterToBase, texts: { [string]: string }, ...): ()
	self.currentText:set(texts["Main"])
end

function GetCharacterToBase.Clean(self: GetCharacterToBase): ()
	self._trove:Destroy()
end

return GetCharacterToBase
