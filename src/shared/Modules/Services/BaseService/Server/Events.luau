local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)
local TaskQueue = require(ReplicatedStorage.Packages.TaskQueue)

local BaseServerEvents = {}

BaseServerEvents.BaseLoaded = Net:RemoteEvent("BaseLoaded")

BaseServerEvents.PlatformCharactersSet = Net:RemoteEvent("BasePlatformCharacterSet")
BaseServerEvents.PlatformCharactersSetQueue = TaskQueue.new(function(...)
	BaseServerEvents.PlatformCharactersSet:FireAllClients(...)
end)

BaseServerEvents.PlatformCollected = Net:RemoteEvent("BasePlatformCollected")
BaseServerEvents.PlatformSold = Net:RemoteEvent("BasePlatformSold")
BaseServerEvents.CharacterStolen = Net:RemoteEvent("BaseCharacterStolen")

BaseServerEvents.BaseLocked = Net:RemoteEvent("BaseLocked")
BaseServerEvents.BaseReset = Net:RemoteEvent("BaseReset")

return BaseServerEvents
