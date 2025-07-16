local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local SettingsServer = require(Services.SettingsService.Server)

local function ToggleSetting(player: Player, wasPurchased: boolean, data: SharedTypes.ProductInfo, index: number)
	if wasPurchased then
		for i, v in data.ToggleableSettings do
			SettingsServer.SetSettingForPlayer(player, i, v)
		end
	end
end

return ToggleSetting
