return {
	Name = "resetplatforms",
	Aliases = { "rp", "rplatforms" },
	Description = "Reset the given player's platforms",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player's platforms you want to reset",
		},
	},
}
