local SharedRebirthData = {}

SharedRebirthData.Constants = {
	CashMultiplier = 1.25,
	StartingCash = 1000,

	LockTimerIncrement = 10,
	LockTimerMaxMult = 6,

	OverCost = 10_000_000,
}

SharedRebirthData.Levels = {
	{
		CashRequired = 100_000,
		Characters = {
			"Uncommon",
			"Uncommon",
			"Rare",
		},
	},
	{
		CashRequired = 200_000,
		Characters = {
			"Rare",
			"Rare",
		},
	},
	{
		CashRequired = 350_000,
		Characters = {
			"Rare",
			"Rare",
			"Epic",
		},
	},
	{
		CashRequired = 500_000,
		Characters = {
			"Epic",
			"Epic",
		},
	},
	{
		CashRequired = 600_000,
		Characters = {
			"Epic",
			"Epic",
			"Legendary",
		},
	},
	{
		CashRequired = 700_000,
		Characters = {
			"Legendary",
			"Legendary",
		},
	},
	{
		CashRequired = 900_000,
		Characters = {
			"Legendary",
			"Legendary",
			"Mythical",
		},
	},
	{
		CashRequired = 1_000_000,
		Characters = {
			"Mythical",
			"Mythical",
			"Unknown",
		},
	},
}

return SharedRebirthData
