local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local Services = ReplicatedStorage.Shared.Modules.Services

local SpawningServer = require(Services.SpawningService.Server)
local Character = require(Services.SpawningService.Server.Character)

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
	spawnerName: string,
	characterName: string
): ()
	self._trove:Add(
		SpawningServer.spawners[SpawningServer.portalIdsByName[spawnerName]].playerBoughtCharacter:Connect(
			function(playerBought: Player, boughtCharacter: Character.Character)
				if playerBought == player and boughtCharacter.Character.Name == characterName then
					finished()
				end
			end
		)
	)
end

function BuyCharacter.Clean(self: BuyCharacter): ()
	self._trove:Destroy()
end

return BuyCharacter
