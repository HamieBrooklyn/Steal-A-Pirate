local SharedSpinnerData = {}

export type Reward = {
	Weight: number,
	Angle: number,
	Rewards: { string },
	Values: { [string]: any },
}

SharedSpinnerData.Testing = {
	Enabled = false, -- false
	GuaranteedReward = -1, -- -1
}

SharedSpinnerData.AwardDelay = 5

SharedSpinnerData.Rewards = {
	[1] = {
		Weight = 0.02,
		Angle = -30,
		Rewards = { "ServerLuck" },
		Values = { ["ServerLuck"] = { Mult = 2, Duration = 2 * 60 } },
	},
	[2] = {
		Weight = 0.005,
		Angle = 30,
		Rewards = { "Tool" },
		Values = { ["Tool"] = { "Grandfather Slap" } },
	},
	[3] = {
		Weight = 0.01,
		Angle = 90,
		Rewards = { "Character" },
		Values = { ["Character"] = { "Mako (Awakened)" } },
	},
	[4] = {
		Weight = 0.55,
		Angle = 150,
		Rewards = { "Statistic" },
		Values = { ["Statistic"] = { { Name = "Cash", IsLeaderstat = true, Amount = 25_000 } } },
	},
	[5] = {
		Weight = 0.075,
		Angle = 210,
		Rewards = { "Statistic" },
		Values = { ["Statistic"] = { { Name = "Cash", IsLeaderstat = true, Amount = 1_000_000 } } },
	},
	[6] = {
		Weight = 0.34,
		Angle = 150,
		Rewards = { "Statistic" },
		Values = { ["Statistic"] = { { Name = "Cash", IsLeaderstat = true, Amount = 100_000 } } },
	},
} :: { Reward }

return SharedSpinnerData
