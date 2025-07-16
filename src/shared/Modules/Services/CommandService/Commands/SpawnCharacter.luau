return {
	Name = "spawncharacter",
	Aliases = { "sc", "spawnc", "spawnchar" },
	Description = "Spawns the given character",
	Group = "Admin",
	Args = {
		{
			Type = "string",
			Name = "CharacterName",
			Description = "The character to spawn",
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "Amount of spawns",
			Optional = true,
		},
		{
			Type = "number",
			Name = "Cooldown",
			Description = "Cooldown between spawns",
			Optional = true,
		},
	},
}
