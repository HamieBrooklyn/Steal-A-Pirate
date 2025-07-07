local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedBaseTypes = require(ReplicatedStorage.Shared.Modules.Services.BaseService.Types)

export type PlayerDataTemplate = {
	Leaderstats: {
		Money: number,
		Rebirths: number,
	},
	RebirthSeed: number,
	Platforms: { SharedBaseTypes.SavedPlatformData },
	CompletedQuests: { string },
}

local PlayerData = {}

PlayerData.Template = {
	Leaderstats = {
		Money = 0,
		Rebirths = 0,
	},
	RebirthSeed = 0,
	Platforms = {},
	CompletedQuests = {},
}

return PlayerData
