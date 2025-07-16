local SpawnData = {}

SpawnData.Spawning = {
	Tag = "Spawner",
	Spawners = {
		["Main Portals"] = {
			DefaultCharacter = "Weak Loafy",

			SpawnCooldown = 2.5, -- 2.5

			Whitelist = {},
			Blacklist = {},

			RarityGuaranteeCooldowns = {
				["Legendary"] = 20, -- 15 * 60
				["Mythical"] = 30, -- 30 * 60
			},
		},
	},

	RaritySpawnRates = {
		Common = 0.45,
		Uncommon = 0.25,
		Rare = 0.12,
		Epic = 0.08,
		Legendary = 0.003,
		Mythical = 0.001,
		Unknown = 0.00005,
	},
}

SpawnData.Characters = {
	Tag = "Character",
	Info = {
		["Weak Loafy"] = { Price = 0, PriceString = "$0", Cashflow = 1, CashflowString = "$1/Sec", Rarity = "Common" },
		["Weak Soggy"] = {
			Price = 25,
			PriceString = "$25",
			Cashflow = 1.5,
			CashflowString = "$1.5/Sec",
			Rarity = "Common",
		},
		["Weak Zuru"] = {
			Price = 100,
			PriceString = "$100",
			Cashflow = 2,
			CashflowString = "$2/Sec",
			Rarity = "Common",
		},
		["Weak Noomie"] = {
			Price = 250,
			PriceString = "$250",
			Cashflow = 3,
			CashflowString = "$3/Sec",
			Rarity = "Common",
		},
		["Weak Sniper"] = {
			Price = 500,
			PriceString = "$500",
			Cashflow = 5,
			CashflowString = "$5/Sec",
			Rarity = "Common",
		},
		["Weak Nika"] = {
			Price = 800,
			PriceString = "$800",
			Cashflow = 6,
			CashflowString = "$6/Sec",
			Rarity = "Common",
		},
		["Baggie"] = {
			Price = 1200,
			PriceString = "$1.2K",
			Cashflow = 10,
			CashflowString = "$10/Sec",
			Rarity = "Uncommon",
		},
		["Evil Fish Man"] = {
			Price = 2000,
			PriceString = "$2K",
			Cashflow = 15,
			CashflowString = "$15/Sec",
			Rarity = "Uncommon",
		},
		["Reindeer"] = {
			Price = 3000,
			PriceString = "$3K",
			Cashflow = 20,
			CashflowString = "$20/Sec",
			Rarity = "Uncommon",
		},
		["Lightning God"] = {
			Price = 4500,
			PriceString = "$4.5K",
			Cashflow = 25,
			CashflowString = "$25/Sec",
			Rarity = "Uncommon",
		},
		["Robot Man"] = {
			Price = 7000,
			PriceString = "$7K",
			Cashflow = 40,
			CashflowString = "$40/Sec",
			Rarity = "Uncommon",
		},
		["Singing Skeleton"] = {
			Price = 11000,
			PriceString = "$11K",
			Cashflow = 60,
			CashflowString = "$60/Sec",
			Rarity = "Uncommon",
		},
		["Loafy Serpent"] = {
			Price = 17000,
			PriceString = "$17K",
			Cashflow = 80,
			CashflowString = "$80/Sec",
			Rarity = "Rare",
		},
		["Loafy"] = {
			Price = 26000,
			PriceString = "$26K",
			Cashflow = 125,
			CashflowString = "$125/Sec",
			Rarity = "Rare",
		},
		["Fire Fist"] = {
			Price = 40000,
			PriceString = "$40K",
			Cashflow = 200,
			CashflowString = "$200/Sec",
			Rarity = "Rare",
		},
		["Zuru"] = {
			Price = 65000,
			PriceString = "$65K",
			Cashflow = 300,
			CashflowString = "$300/Sec",
			Rarity = "Rare",
		},
		["Sniper"] = {
			Price = 100000,
			PriceString = "$100K",
			Cashflow = 500,
			CashflowString = "$500/Sec",
			Rarity = "Rare",
		},
		["Soggy"] = {
			Price = 155000,
			PriceString = "$155K",
			Cashflow = 750,
			CashflowString = "$750/Sec",
			Rarity = "Rare",
		},
		["Noomie"] = {
			Price = 250000,
			PriceString = "$250K",
			Cashflow = 1150,
			CashflowString = "$1.2K/Sec",
			Rarity = "Epic",
		},
		["Nika"] = {
			Price = 375000,
			PriceString = "$375K",
			Cashflow = 1800,
			CashflowString = "$1.8K/Sec",
			Rarity = "Epic",
		},
		["Room"] = {
			Price = 600000,
			PriceString = "$600K",
			Cashflow = 2800,
			CashflowString = "$2.8K/Sec",
			Rarity = "Epic",
		},
		["Strong Swordsman"] = {
			Price = 900000,
			PriceString = "$900K",
			Cashflow = 4500,
			CashflowString = "$4.5K/Sec",
			Rarity = "Epic",
		},
		["Doffy"] = {
			Price = 1450000,
			PriceString = "$1.45M",
			Cashflow = 6800,
			CashflowString = "$6.8K/Sec",
			Rarity = "Epic",
		},
		["Red Hair"] = {
			Price = 2250000,
			PriceString = "$2.25M",
			Cashflow = 10500,
			CashflowString = "$10.5K/Sec",
			Rarity = "Epic",
		},
		["Ivanoob"] = {
			Price = 3500000,
			PriceString = "$3.5M",
			Cashflow = 16500,
			CashflowString = "$16.5K/Sec",
			Rarity = "Epic",
		},
		["Jimbay"] = {
			Price = 5500000,
			PriceString = "$5.5M",
			Cashflow = 26000,
			CashflowString = "$26K/Sec",
			Rarity = "Legendary",
		},
		["Loafy G4"] = {
			Price = 8500000,
			PriceString = "$8.5M",
			Cashflow = 41000,
			CashflowString = "$41K/Sec",
			Rarity = "Legendary",
		},
		["Dark"] = {
			Price = 13000000,
			PriceString = "$13M",
			Cashflow = 64000,
			CashflowString = "$64K/Sec",
			Rarity = "Legendary",
		},
		["Phoenix"] = {
			Price = 21000000,
			PriceString = "$21M",
			Cashflow = 100000,
			CashflowString = "$100K/Sec",
			Rarity = "Legendary",
		},
		["Quake Man"] = {
			Price = 32500000,
			PriceString = "$32.5M",
			Cashflow = 156000,
			CashflowString = "$156K/Sec",
			Rarity = "Legendary",
		},
		["Large Mum"] = {
			Price = 50500000,
			PriceString = "$50.5M",
			Cashflow = 245000,
			CashflowString = "$245K/Sec",
			Rarity = "Legendary",
		},
		["Rayler"] = {
			Price = 79000000,
			PriceString = "$79M",
			Cashflow = 383000,
			CashflowString = "$383K/Sec",
			Rarity = "Mythical",
		},
		["Loafy G5"] = {
			Price = 125000000,
			PriceString = "$125M",
			Cashflow = 600000,
			CashflowString = "$600K/Sec",
			Rarity = "Mythical",
		},
		["Beast"] = {
			Price = 193500000,
			PriceString = "$193.5M",
			Cashflow = 940000,
			CashflowString = "$940K/Sec",
			Rarity = "Mythical",
		},
		["Golden Man"] = {
			Price = 2000000,
			PriceString = "$2M",
			Cashflow = 10000,
			CashflowString = "$10K/Sec",
			Rarity = "Unknown",
		},
	},
}

return SpawnData
