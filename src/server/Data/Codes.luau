local Codes = {}

Codes["GORO"] = {
	RewardType = "Character",
	ConditionTypes = { "FreeTimedCharacter", "Character" },

	CharacterName = "Goro (Rare)",
}

Codes["FUN"] = {
	RewardType = "Statistic",
	ConditionTypes = {},

	Statistics = { ["Cash"] = 5000 },
}

return Codes
