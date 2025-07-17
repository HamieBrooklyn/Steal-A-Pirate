local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)

local Character = require(script.Character)
local Spawner = require(script.Spawner)

local Observers = require(ReplicatedStorage.Packages.Observers)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Net = require(ReplicatedStorage.Packages.Net)

local player = Players.LocalPlayer

local SpawningClient = {
	spawners = {} :: { [string]: Spawner.Spawner },
	spawnerIdByName = {} :: { [string]: string },

	characters = {} :: { [string]: Character.Character },
	characterNamesByRarity = {} :: { [string]: { string } },
	characterNamesByIndex = {} :: { string },
}

function SpawningClient.init()
	local index = 0
	for i: string, v: SharedTypes.CharacterData in SharedData.Characters.Info do
		if not SpawningClient.characterNamesByRarity[v.Rarity] then
			SpawningClient.characterNamesByRarity[v.Rarity] = {}
		end
		table.insert(SpawningClient.characterNamesByRarity[v.Rarity], i)
		index += 1
		SpawningClient.characterNamesByIndex[index] = i
	end
	table.sort(SpawningClient.characterNamesByIndex, function(a, b)
		return SharedData.Characters.Info[a].Cashflow < SharedData.Characters.Info[b].Cashflow
	end)
	for _, v in SpawningClient.characterNamesByRarity do
		table.sort(v, function(a, b)
			return a < b
		end)
	end

	Net:Connect("SpawningCharacterMovingTo", function(character: Model, destination: string)
		local rootStream = Streamable.primary(character)
		rootStream:Observe(function(primary)
			primary:WaitForChild("PirateInteract").Enabled = destination ~= tostring(player.UserId)
			rootStream:Destroy()
		end)
	end)

	observeCharacter(player, function()
		local infoPromptsContainer = Instance.new("Folder")
		infoPromptsContainer.Name = "InfoPrompts"
		infoPromptsContainer.Parent = player:WaitForChild("PlayerGui")
	end)

	Observers.observeTag("Spawner", function(instance)
		local spawner = Spawner.new(instance)
		SpawningClient.spawners[spawner.id] = spawner
		SpawningClient.spawnerIdByName[instance.Name] = spawner.id
		return function()
			spawner:Destroy()
			SpawningClient.spawners[spawner.id] = nil
		end
	end)
	Observers.observeTag(SharedData.Characters.Tag, function(instance)
		local characterData: SharedTypes.CharacterData? = SharedData.Characters.Info[instance.Name]
		if not characterData then
			warn(instance.Name .. " was not found as a character data")
			return
		end

		local character = Character.new(instance, characterData)

		SpawningClient.characters[character.id] = character

		return function()
			SpawningClient.characters[character.id] = nil
			character:Destroy()
		end
	end)

	RunService.Heartbeat:Connect(function()
		for _, v in SpawningClient.spawners do
			v:Heartbeat()
		end
	end)
end

return SpawningClient
