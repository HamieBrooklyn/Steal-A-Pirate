local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Packages.Net)
local SpawningServerEvents = {}

SpawningServerEvents.CharacterMovingTo = Net:RemoteEvent("SpawningCharacterMovingTo")
SpawningServerEvents.BoughtCharacter = Net:RemoteEvent("SpawningBoughtCharacter")

return SpawningServerEvents
