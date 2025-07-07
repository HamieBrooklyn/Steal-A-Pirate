local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)

local Character = require(script.Character)

local Observers = require(ReplicatedStorage.Packages.Observers)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local Net = require(ReplicatedStorage.Packages.Net)

local player = Players.LocalPlayer

local SpawningClient = {
	characters = {} :: { [string]: Character.Character },
}

function SpawningClient.init()
	Net:Connect("SpawningCharacterMovingTo", function(character: Model, destination: string)
		character.PrimaryPart:WaitForChild("PirateInteract").Enabled = destination ~= tostring(player.UserId)
	end)

	observeCharacter(player, function()
		local infoPromptsContainer = Instance.new("Folder")
		infoPromptsContainer.Name = "InfoPrompts"
		infoPromptsContainer.Parent = player:WaitForChild("PlayerGui")
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
end

return SpawningClient
