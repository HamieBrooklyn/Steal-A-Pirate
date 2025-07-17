local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)

local Trove = require(ReplicatedStorage.Packages.Trove)

local GetCharacterToPlase = {}
GetCharacterToPlase.__index = GetCharacterToPlase

type self = {
	_trove: Trove.Trove,
}
export type GetCharacterToPlase = typeof(setmetatable({} :: self, GetCharacterToPlase))

function GetCharacterToPlase.new(player: Player, texts: { [string]: string }, ...): GetCharacterToPlase
	local self = setmetatable({}, GetCharacterToPlase) :: GetCharacterToPlase

	self._trove = Trove.new()

	return self
end

function GetCharacterToPlase.Start(
	self: GetCharacterToPlase,
	finished: () -> (),
	player: Player,
	texts: { [string]: string },
	characterName: string
): ()
	local base = BaseServer.GetPlayerBase(player)
	self._trove:Add(base.characterAdded:Connect(function(addedCharName: string)
		if addedCharName == characterName then
			finished()
		end
	end))
end

function GetCharacterToPlase.Clean(self: GetCharacterToPlase): ()
	self._trove:Destroy()
end

return GetCharacterToPlase
