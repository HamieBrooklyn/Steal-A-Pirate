local SharedRebirthData = {}

SharedRebirthData.Constants = {
	BeliMultiplier = 1.25,
	StartingBeli = 1000,
	LockTimerIncrement = 10,
	OverCost = 10_000_000,
}

SharedRebirthData.Levels = {
	{
		BeliRequired = 100_000,
		Characters = {
			"Uncommon",
			"Uncommon",
			"Rare",
		},
	},
	{
		BeliRequired = 200_000,
		Characters = {
			"Rare",
			"Rare",
		},
	},
	{
		BeliRequired = 350_000,
		Characters = {
			"Rare",
			"Rare",
			"Epic",
		},
	},
	{
		BeliRequired = 500_000,
		Characters = {
			"Epic",
			"Epic",
		},
	},
	{
		BeliRequired = 600_000,
		Characters = {
			"Epic",
			"Epic",
			"Legendary",
		},
	},
	{
		BeliRequired = 700_000,
		Characters = {
			"Legendary",
			"Legendary",
		},
	},
	{
		BeliRequired = 900_000,
		Characters = {
			"Legendary",
			"Legendary",
			"Mythical",
		},
	},
	{
		BeliRequired = 1_000_000,
		Characters = {
			"Mythical",
			"Mythical",
			"Unknown",
		},
	},
}

return SharedRebirthData
