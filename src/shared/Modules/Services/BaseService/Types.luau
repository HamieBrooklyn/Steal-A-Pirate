local BaseTypes = {}

export type SavedPlatformData = {
	CharacterName: string,
	LastCollectedTime: number,
	Mutations: { string }?,
}

export type PlatformIdData = {
	baseId: string,
	platformId: string,
}

export type PlatformSyncData = {
	platformId: string,
	characterName: string,
	lastCollectedTime: number,
}
export type BaseSyncData = {
	baseId: string,
	ownerId: string,
	lastLockedTime: number,
	platforms: { PlatformSyncData },
}

return BaseTypes
