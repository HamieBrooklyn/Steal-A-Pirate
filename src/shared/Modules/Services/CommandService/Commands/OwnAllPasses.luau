return {
	Name = "ownAllPasses",
	Aliases = { "oap" },
	Description = "Makes given player own all passes in this server",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player to grant all gamepasses for",
		},
		-- {
		-- 	Type = "boolean",
		-- 	Name = "Owns",
		-- 	Description = "Should the given player have all the gamepasses in this server?",
		-- },
	},
}
