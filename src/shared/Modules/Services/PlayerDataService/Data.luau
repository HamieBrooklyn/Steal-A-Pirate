local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedBaseTypes = require(ReplicatedStorage.Shared.Modules.Services.BaseService.Types)

export type SavedTool = {
	Amount: number,
	Equipped: boolean,
}
export type PlayerDataTemplate = {
	Leaderstats: {
		Cash: number,
		Rebirths: number,
		Steals: number,
	},
	UnlockedCharacters: { string },
	CompletedQuests: { string },
	CodesRedeemed: { string },
	CachedSpawns: { string },
	Platforms: { SharedBaseTypes.SavedPlatformData },
	Tools: { [string]: { Amount: number, SaveOnDeath: boolean? } },

	PirateOnDisplay: string?,

	RebirthSeed: number,

	Spins: number,
	SpinsClaimedDate: string,

	TotalDonations: number,
	TotalEarnings: number,
}

local PlayerData = {}

PlayerData.Template = {
	Leaderstats = {
		Cash = 0,
		Rebirths = 0,
		Steals = 0,
	},
	UnlockedCharacters = {},
	CompletedQuests = {},
	CodesRedeemed = {},
	CachedSpawns = {},
	Platforms = {},
	Tools = {},

	RebirthSeed = 0,

	Spins = 0,
	SpinsClaimedDate = "",

	Steals = 0,
	TotalDonations = 0,
	TotalEarnings = 0,
}

return PlayerData
