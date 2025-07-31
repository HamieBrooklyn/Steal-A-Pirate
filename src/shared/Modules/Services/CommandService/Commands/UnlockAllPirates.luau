return {
	Name = "unlockallpirates",
	Aliases = { "uap", "unlockap", "allpirates" },
	Description = "Unlocks all pirates for given player",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player that will unlock all pirates",
		},
	},
}
