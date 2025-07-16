local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SpawningClient = require(Services.SpawningService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local Value = Fusion.Value
local scoped, peek = Fusion.scoped, Fusion.peek

local IndexClient = {}

function IndexClient.init()
	local scope = scoped(Fusion, {
		IndexMenu = require(script.IndexMenu),
		CharacterView = require(script.IndexMenu.CharacterView),
	})

	local nonUnlockedCharacters = {}
	for _, v in SpawningClient.characterNamesByIndex do
		nonUnlockedCharacters[v] = false
	end
	IndexClient.unlockedCharacterNames = Value(scope, nonUnlockedCharacters) :: Fusion.Value<{ [string]: boolean }, any>
	local charactersUnlockedCount = Value(scope, 0)

	Net:Connect("UnlockedNewCharacters", function(newCharacters: { string })
		local unlockedNamesState = table.clone(peek(IndexClient.unlockedCharacterNames))
		for _, v in newCharacters do
			unlockedNamesState[v] = true
			charactersUnlockedCount:set(peek(charactersUnlockedCount) + 1)
		end
		IndexClient.unlockedCharacterNames:set(unlockedNamesState)
	end)

	scope:IndexMenu({
		unlockedCharacterNames = IndexClient.unlockedCharacterNames,
		charactersUnlockedCount = charactersUnlockedCount,
	})
end

return IndexClient
