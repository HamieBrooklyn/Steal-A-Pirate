return {
	Name = "setstatistic",
	Aliases = { "ss", "sets", "setstat" },
	Description = "Sets the given stat name to the given value",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player to set the stat for",
		},
		{
			Type = "string",
			Name = "StatName",
			Description = "The stat to set",
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "The new amount",
			Optional = true,
		},
	},
}
