local SpawnData = {}

SpawnData.WalkSpeed = 15 -- 15

SpawnData.Spawning = {
	Tag = "Spawner",
	Spawners = {
		["Main Portals"] = {
			DefaultCharacter = "Weak Loafy",

			SpawnCooldown = 2.5, -- 2.5

			Whitelist = {},
			Blacklist = {},

			RarityGuaranteeCooldowns = {
				["Legendary"] = 15 * 60, -- 15 * 60
				["Mythical"] = 35 * 60, -- 30 * 60
			},
		},
	},

	RaritySpawnRates = {
		Common = 0.45,
		Uncommon = 0.25,
		Rare = 0.12,
		Epic = 0.08,
		Legendary = 0.03,
		Mythical = 0.01,
		Unknown = 0.0005,
	},
	MutationChances = {
		None = 0.95, -- 0.95
		-- Big = 0.4, -- 0.1
		-- Small = 0.4, -- 0.1
		-- ObservationHaki = 0.01, -- 0.01
		-- ArnamentHaki = 0.001, -- 0.001
		-- ConquerersHaki = 0.0001, -- 0.0001
	},
}

SpawnData.Mutations = {
	-- Big = {
	-- 	Class = "Scale",
	-- 	Mult = 1.25,
	-- 	Values = {
	-- 		Scale = 1.1,
	-- 	},
	-- },
	-- Small = {
	-- 	Class = "Scale",
	-- 	Mult = 1.25,
	-- 	Values = {
	-- 		Scale = 0.9,
	-- 	},
	-- },
	-- ObservationHaki = {
	-- 	Class = "Haki",
	-- 	Mult = 2,

	-- 	Title = "Observation Haki",
	-- 	Gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Haki.Observation,

	-- 	Values = {
	-- 		VFX = ReplicatedStorage.Assets.VFX.Haki.Observation,
	-- 	},
	-- },
	-- ArmenentHaki = {
	-- 	Class = "Haki",
	-- 	Mult = 5,

	-- 	Title = "Armenent Haki",
	-- 	Gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Haki.Armenent,

	-- 	Values = {
	-- 		VFX = ReplicatedStorage.Assets.VFX.Haki.Armenent,
	-- 	},
	-- },
	-- ConquerersHaki = {
	-- 	Class = "Haki",
	-- 	Mult = 10,

	-- 	Title = "Conquerers Haki",
	-- 	Gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Haki.Conquerers,

	-- 	Values = {
	-- 		VFX = ReplicatedStorage.Assets.VFX.Haki.Conquerer,
	-- 	},
	-- },
}

SpawnData.ImportantRarities = {
	"Legendary",
	"Mythical",
	"Unknown",
}

SpawnData.Characters = {
	Tag = "Character",
	Info = {
		{
			Name = "School Yuto",
			Price = 0,
			PriceString = "$0",
			Cashflow = 1,
			CashflowString = "$1/Sec",
			Rarity = "Common",
		},
		{
			Name = "Rizu",
			Price = 25,
			PriceString = "$25",
			Cashflow = 1.5,
			CashflowString = "$1.5/Sec",
			Rarity = "Common",
		},
		{
			Name = "Noriko",
			Price = 100,
			PriceString = "$100",
			Cashflow = 2,
			CashflowString = "$2/Sec",
			Rarity = "Common",
		},
		{
			Name = "Mako",
			Price = 250,
			PriceString = "$250",
			Cashflow = 3,
			CashflowString = "$3/Sec",
			Rarity = "Common",
		},
		{
			Name = "Mezuki",
			Price = 500,
			PriceString = "$500",
			Cashflow = 5,
			CashflowString = "$5/Sec",
			Rarity = "Common",
		},
		{
			Name = "Misu",
			Price = 800,
			PriceString = "$800",
			Cashflow = 6,
			CashflowString = "$6/Sec",
			Rarity = "Common",
		},
		{
			Name = "Yuto",
			Price = 1200,
			PriceString = "$1.2K",
			Cashflow = 10,
			CashflowString = "$10/Sec",
			Rarity = "Uncommon",
		},
		{
			Name = "Nanao (weak)",
			Price = 2000,
			PriceString = "$2K",
			Cashflow = 15,
			CashflowString = "$15/Sec",
			Rarity = "Uncommon",
		},
		{
			Name = "Shira",
			Price = 3000,
			PriceString = "$3K",
			Cashflow = 20,
			CashflowString = "$20/Sec",
			Rarity = "Uncommon",
		},
		{
			Name = "Utara",
			Price = 4500,
			PriceString = "$4.5K",
			Cashflow = 25,
			CashflowString = "$25/Sec",
			Rarity = "Uncommon",
		},
		{
			Name = "Meira",
			Price = 7000,
			PriceString = "$7K",
			Cashflow = 40,
			CashflowString = "$40/Sec",
			Rarity = "Uncommon",
		},
		{
			Name = "Sakano (Weak)",
			Price = 11000,
			PriceString = "$11K",
			Cashflow = 60,
			CashflowString = "$60/Sec",
			Rarity = "Uncommon",
		},
		{
			Name = "Haneko",
			Price = 17000,
			PriceString = "$17K",
			Cashflow = 80,
			CashflowString = "$80/Sec",
			Rarity = "Rare",
		},
		{
			Name = "Chiru",
			Price = 26000,
			PriceString = "$26K",
			Cashflow = 125,
			CashflowString = "$125/Sec",
			Rarity = "Rare",
		},
		{
			Name = "Joro",
			Price = 40000,
			PriceString = "$40K",
			Cashflow = 200,
			CashflowString = "$200/Sec",
			Rarity = "Rare",
		},
		{
			Name = "Sashiro",
			Price = 65000,
			PriceString = "$65K",
			Cashflow = 300,
			CashflowString = "$300/Sec",
			Rarity = "Rare",
		},
		{
			Name = "Yuno",
			Price = 100000,
			PriceString = "$100K",
			Cashflow = 500,
			CashflowString = "$500/Sec",
			Rarity = "Rare",
		},
		{
			Name = "Goro",
			Price = 155000,
			PriceString = "$155K",
			Cashflow = 750,
			CashflowString = "$750/Sec",
			Rarity = "Rare",
		},
		{
			Name = "Tenji",
			Price = 250000,
			PriceString = "$250K",
			Cashflow = 1150,
			CashflowString = "$1.2K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Yukari",
			Price = 375000,
			PriceString = "$375K",
			Cashflow = 1800,
			CashflowString = "$1.8K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Mahiru",
			Price = 600000,
			PriceString = "$600K",
			Cashflow = 2800,
			CashflowString = "$2.8K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Kazumo",
			Price = 900000,
			PriceString = "$900K",
			Cashflow = 4500,
			CashflowString = "$4.5K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Tenji",
			Price = 1450000,
			PriceString = "$1.45M",
			Cashflow = 6800,
			CashflowString = "$6.8K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Gento",
			Price = 2250000,
			PriceString = "$2.25M",
			Cashflow = 10500,
			CashflowString = "$10.5K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Urana)",
			Price = 3500000,
			PriceString = "$3.5M",
			Cashflow = 16500,
			CashflowString = "$16.5K/Sec",
			Rarity = "Epic",
		},
		{
			Name = "Mako (Awakened)",
			Price = 5500000,
			PriceString = "$5.5M",
			Cashflow = 26000,
			CashflowString = "$26K/Sec",
			Rarity = "Legendary",
		},
		{
			Name = "Sakano (Shadow)",
			Price = 8500000,
			PriceString = "$8.5M",
			Cashflow = 41000,
			CashflowString = "$41K/Sec",
			Rarity = "Legendary",
		},
		{
			Name = "Ragano",
			Price = 13000000,
			PriceString = "$13M",
			Cashflow = 64000,
			CashflowString = "$64K/Sec",
			Rarity = "Legendary",
		},
		{
			Name = "Goro (Broken Seal)",
			Price = 21000000,
			PriceString = "$21M",
			Cashflow = 100000,
			CashflowString = "$100K/Sec",
			Rarity = "Legendary",
		},
		{
			Name = "Higure",
			Price = 32500000,
			PriceString = "$32.5M",
			Cashflow = 156000,
			CashflowString = "$156K/Sec",
			Rarity = "Legendary",
		},
		{
			Name = "Hakuma",
			Price = 50500000,
			PriceString = "$50.5M",
			Cashflow = 245000,
			CashflowString = "$245K/Sec",
			Rarity = "Legendary",
		},
		{
			Name = "Goro (Mentor)",
			Price = 79000000,
			PriceString = "$79M",
			Cashflow = 383000,
			CashflowString = "$383K/Sec",
			Rarity = "Mythical",
		},
		{
			Name = "Sakano (True Form)",
			Price = 125000000,
			PriceString = "$125M",
			Cashflow = 600000,
			CashflowString = "$600K/Sec",
			Rarity = "Mythical",
		},
		{
			Name = "Yuto (Final Form)",
			Price = 20000000,
			PriceString = "$2M",
			Cashflow = 1000000,
			CashflowString = "$1M/Sec",
			Rarity = "Unknown",
		},
	},
}

return SpawnData
