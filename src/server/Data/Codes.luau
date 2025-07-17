local Codes = {}

Codes["AYCE"] = {
	RewardType = "Character",
	ConditionTypes = { "FreeTimedCharacter", "Character" },

	CharacterName = "Fire Fist",
}

Codes["FUN"] = {
	RewardType = "Statistic",
	ConditionTypes = {},

	Statistics = { ["Beli"] = 5000 },
}

return Codes
