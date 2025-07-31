local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gradients = ReplicatedStorage.Assets.Templates.Gui.Gradients

export type ShopToolData = {
	Order: number,

	Title: string?,
	Description: string?,
	Image: string?,

	CashCost: number,
	RebirthsRequired: number,
	Limit: number,

	TitleGradient: UIGradient?,
	DescriptionGradient: UIGradient?,
}

local SharedToolData = {}

SharedToolData.StarterTool = "Slap"

SharedToolData.UpgradeableTools = {
	["Slap"] = {
		{
			Level = 1,
			ToolName = "Slap",
		},
		{
			Level = 2,
			ToolName = "Stone Slap",
		},
		{
			Level = 3,
			ToolName = "Conquerer Slap",
		},
	},
}

SharedToolData.ShopTools = {
	["Banana"] = {
		Order = 1,

		Title = "Banana",
		Description = "The classic slip-and-fall trap. Drop a banana peel to make any player who steps on it slip.",
		Image = "rbxassetid://83989247926383",
		GetType = "Stock",
		Upgrades = "Slap",

		CashCost = 500,
		RebirthsRequired = 0,
		Limit = 5,

		TitleGradient = Gradients.RipeBanana,
		DescriptionGradient = Gradients.Rock,
	},
	["Stone Slap"] = {
		Order = 2,

		Title = "Stone Slap",
		Description = "SLAM! BOOM! POW!",
		Image = "rbxassetid://108340787857009",
		GetType = "Equip",
		Upgrades = "Slap",

		CashCost = 2500,
		RebirthsRequired = 1,
		Limit = 1,

		TitleGradient = Gradients.Rock,
		DescriptionGradient = Gradients.Rock,
	},
	["Jump Jump Fruit"] = {
		Order = 3,

		Title = "Jump Jump Fruit",
		Description = "Jump higher than ever before",
		Image = "rbxassetid://74579165571055",
		GetType = "Stock",

		CashCost = 10_000,
		RebirthsRequired = 2,
		Limit = 3,

		TitleGradient = Gradients.Apple,
		DescriptionGradient = Gradients.Rock,
	},
	["Speed Speed Fruit"] = {
		Order = 4,

		Title = "Speed Speed Fruit",
		Description = "Makes you go vroooooom",
		Image = "rbxassetid://95440524456415",
		GetType = "Stock",

		CashCost = 15_000,
		RebirthsRequired = 2,
		Limit = 3,

		TitleGradient = Gradients.Banana,
		DescriptionGradient = Gradients.Rock,
	},
	["FreezeRay"] = {
		Order = 5,

		Title = "Freeze Ray",
		Description = "Makes someone feel really cold",
		Image = "rbxassetid://103518905443465",
		GetType = "Equip",

		CashCost = 500,
		RebirthsRequired = 3,
		Limit = 1,

		TitleGradient = Gradients.Blueberries,
		DescriptionGradient = Gradients.Rock,
	},
	["BearTrap"] = {
		Order = 6,

		Title = "Bear Trap",
		Description = "Secure your base... or dont.",
		Image = "rbxassetid://134930545845280",
		GetType = "Stock",

		CashCost = 30_000,
		RebirthsRequired = 4,
		Limit = 5,

		TitleGradient = Gradients.Coconut,
		DescriptionGradient = Gradients.Rock,
	},
	["Invis Invis Fruit"] = {
		Order = 7,

		Title = "Invis Invis Fruit",
		Description = "Become nothing",
		Image = "rbxassetid://139267520805922",
		GetType = "Stock",

		CashCost = 50_000,
		RebirthsRequired = 5,
		Limit = 1,

		TitleGradient = Gradients.WhiteApple,
		DescriptionGradient = Gradients.Rock,
	},
	["Conquerer Slap"] = {
		Order = 8,

		Title = "Conquerer Slap",
		Description = "Use this against whom you hate the most. Or anyone.",
		Image = "rbxassetid://102671111201439",
		GetType = "Equip",
		Upgrades = "Slap",

		CashCost = 75_000,
		RebirthsRequired = 6,
		Limit = 1,

		TitleGradient = Gradients.RedApple,
		DescriptionGradient = Gradients.Rock,
	},
	["Bomb Bomb Fruit"] = {
		Order = 9,

		Title = "Bomb Bomb Fruit",
		Description = "Pretty self explanitory.",
		Image = "rbxassetid://106562489126717",
		GetType = "Stock",

		CashCost = 90_000,
		RebirthsRequired = 7,
		Limit = 3,

		TitleGradient = Gradients.Blackberry,
		DescriptionGradient = Gradients.Rock,
	},
	["Unlock Unlock Fruit"] = {
		Order = 10,

		Title = "Unlock Unlock Fruit",
		Description = "😈",
		Image = "rbxassetid://106844447244222",
		GetType = "Stock",

		CashCost = 150_000,
		RebirthsRequired = 8,
		Limit = 3,

		TitleGradient = Gradients.Ice,
		DescriptionGradient = Gradients.Rock,
	},
} :: { ShopToolData }

return SharedToolData
