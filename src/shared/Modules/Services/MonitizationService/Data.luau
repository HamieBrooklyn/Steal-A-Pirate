local SharedTypes = require(script.Parent.Types)

local SharedMonitizationData = {}

SharedMonitizationData.Products = {
	["10Donation"] = {
		Id = 3333183922,
		ProductType = "Product",
		ServerFunctionTypes = { "Donation" },

		Amounts = { 10 },
	},
	["100Donation"] = {
		Id = 3333183923,
		ProductType = "Product",
		ServerFunctionTypes = { "Donation" },

		Amounts = { 10 },
	},
	["1000Donation"] = {
		Id = 3333183928,
		ProductType = "Product",
		ServerFunctionTypes = { "Donation" },

		Amounts = { 10 },
	},
	["10KDonation"] = {
		Id = 3333183925,
		ProductType = "Product",
		ServerFunctionTypes = { "Donation" },

		Amounts = { 10 },
	},
	["100KDonation"] = {
		Id = 3333183917,
		ProductType = "Product",
		ServerFunctionTypes = { "Donation" },

		Amounts = { 10 },
	},
	["1MDonation"] = {
		Id = 3333183919,
		ProductType = "Product",
		ServerFunctionTypes = { "Donation" },

		Amounts = { 10 },
	},

	["10KBeli"] = {
		Id = 3333771747,
		ProductType = "Product",
		ServerFunctionTypes = { "Leaderstat" },

		StatNames = { "Beli" },
		Amounts = { 10_000 },
	},
	["100KBeli"] = {
		Id = 3333771750,
		ProductType = "Product",
		ServerFunctionTypes = { "Leaderstat" },

		StatNames = { "Beli" },
		Amounts = { 100_000 },
	},
	["500KBeli"] = {
		Id = 3333771748,
		ProductType = "Product",
		ServerFunctionTypes = { "Leaderstat" },

		StatNames = { "Beli" },
		Amounts = { 500_000 },
	},
	["2.5MBeli"] = {
		Id = 3333771754,
		ProductType = "Product",
		ServerFunctionTypes = { "Leaderstat" },

		StatNames = { "Beli" },
		Amounts = { 2_500_000 },
	},
	["10MBeli"] = {
		Id = 3333771753,
		ProductType = "Product",
		ServerFunctionTypes = { "Leaderstat" },

		StatNames = { "Beli" },
		Amounts = { 10_000_000 },
	},

	["UnlockBase"] = {
		Id = 3335271702,
		ProductType = "Product",
		ServerFunctionTypes = { "UnlockBase" },
	},
	["LockBase10Min"] = {
		Id = 3335281047,
		ProductType = "Product",
		ServerFunctionTypes = { "LockBase" },

		Durations = { 10 * 60 }, -- 10 * 60
	},
	["LockBase30Min"] = {
		Id = 3335281046,
		ProductType = "Product",
		ServerFunctionTypes = { "LockBase" },

		Durations = { 30 * 60 }, -- 30 * 60
	},

	["LimitedCharacter"] = {
		Id = 3336689904,
		ProductType = "Product",
		ServerFunctionTypes = { "Character" },

		CharacterNames = { "Zuru" },
	},

	["2XServerLuck"] = {
		Id = 3333776801,
		ProductType = "Gamepass",

		ServerFunctionTypes = { "ServerLuckBoost" },

		Portals = { "Main Portals" },
		Durations = { 10 }, -- 30 * 60
		Amounts = { 2 },
	},

	["StarterPack"] = {
		Id = 1318134425,
		ProductType = "Gamepass",
		ServerFunctionTypes = { "Leaderstat", "Character" },

		StatNames = { "Beli" },
		CharacterNames = { "Jimbay" },
		Amounts = { 2500 },
	},
	["2XMoney"] = {
		Id = 1317946130,
		ProductType = "Gamepass",
	},
	["AutoCollect"] = {
		Id = 1318314352,
		ProductType = "Gamepass",
		ServerFunctionTypes = { "ToggleSetting" },
		ToggleableSettings = { ["AutoCollect"] = true },
	},
	["FlyingCarpet"] = {
		Id = 1319317896,
		ProductType = "Gamepass",

		ServerFunctionTypes = { "GiveTool" },
		Values = { { ["FlyingCarpet"] = { Amount = 1, Permanent = true, SaveOnDeath = true } } },
	},
} :: { SharedTypes.ProductInfo }

return SharedMonitizationData
