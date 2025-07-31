return {
	Name = "givepirate",
	Aliases = { "gp", "givep" },
	Description = "Spawn a pirate in someone's base, if its full it puts it in their cached pirates.",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player to give the pirate to",
		},
		{
			Type = "string",
			Name = "Pirate Name",
			Description = "The pirate to give",
		},
		{
			Type = "number",
			Name = "The amount",
			Description = "How many?",
			Optional = true,
		},
	},
}
