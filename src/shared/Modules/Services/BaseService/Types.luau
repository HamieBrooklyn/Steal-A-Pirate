local BaseTypes = {}

export type SavedPlatformData = {
	CharacterName: string,
	LastCollectedTime: number,
}
export type BaseSyncData = {
	baseId: string,
	ownerId: string,
	lastLockedTime: number,
	platforms: {
		{
			platformId: string,
			characterName: string,
			lastCollectedTime: number,
		}
	},
}

return BaseTypes
