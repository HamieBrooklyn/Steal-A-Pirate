local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedBaseTypes = require(ReplicatedStorage.Shared.Modules.Services.BaseService.Types)

export type SavedTool = {
	Amount: number,
	SaveOnDeath: boolean?,
}
export type PlayerDataTemplate = {
	Leaderstats: {
		Cash: number,
		Rebirths: number,
	},
	UnlockedCharacters: { string },
	CompletedQuests: { string },
	CodesRedeemed: { string },
	Platforms: { SharedBaseTypes.SavedPlatformData },
	Tools: { [string]: { Amount: number, SaveOnDeath: boolean? } },

	RebirthSeed: number,

	Steals: number,
	Spins: number,
	TotalDonations: number,
	TotalEarnings: number,
}

local PlayerData = {}

PlayerData.Template = {
	Leaderstats = {
		Cash = 0,
		Rebirths = 0,
	},
	UnlockedCharacters = {},
	CompletedQuests = {},
	CodesRedeemed = {},
	Platforms = {},
	Tools = {},

	RebirthSeed = 0,

	Steals = 0,
	TotalDonations = 0,
	TotalEarnings = 0,
}

return PlayerData
