local SharedTypes = require(script.Parent.Types)

local SharedSettingsData = {}

SharedSettingsData.Settings = {
	["AutoCollect"] = {
		SettingType = "Toggle",
		ServerFunctionality = "AutoCollect",

		ClientConditions = { "OwnsGamepass" },
		ServerConditions = { "OwnsGamepass" },
		GamepassKeys = { "AutoCollect" },

		Title = "Auto collect",
		Description = "Toggle automation of cash collecting.",

		Default = false,

		Weight = 1,
	},
} :: { SharedTypes.SettingData }

return SharedSettingsData
