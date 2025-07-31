local SpawningTypes = {}

export type SpawnerData = {
	SpawnCooldown: number,

	DefaultCharacter: string,

	PossibleSpawns: { string },
	Whitelist: { string },
	Blacklist: { string },

	RarityGuaranteeCooldowns: { [string]: number },
}

export type CharacterData = {
	Name: string,

	Price: number,
	PriceString: string,

	Cashflow: number,
	CashflowString: string,

	Rarity: string,
}

export type MutationData = {
	Class: string,
	Mult: number,

	Title: string,
	Gradient: UIGradient,

	Values: { [string]: any },
}

return SpawningTypes
