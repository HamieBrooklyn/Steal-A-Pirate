local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)

local BaseClientEvents = {
	CollectPlatform = Net:RemoteEvent("BaseCollectPlatform"),
	GetBases = Net:RemoteFunction("GetBases"),
	PlatformCharacterInteract = Net:RemoteEvent("BasePlatformCharacterInteract"),
	LockBaseAttempt = Net:RemoteEvent("LockBaseAttempt"),
}

return BaseClientEvents
