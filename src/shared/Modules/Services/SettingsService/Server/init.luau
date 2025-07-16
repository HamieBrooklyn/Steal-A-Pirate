local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedData = require(script.Parent.Data)

local PlayerDataServer = require(Services.PlayerDataService.Server)

local Net = require(ReplicatedStorage.Packages.Net)

local SettingsServer = {
	playerSettings = {} :: { { [string]: any } },
}
SettingsServer.playersSettingsWasSet = Net:RemoteEvent("PlayersSettingsWasSet")

function SettingsServer.SetSettingForPlayer(player: Player, settingKey: string, value: any)
	SettingsServer.playersSettingsWasSet:FireAllClients({
		[tostring(player.UserId)] = {
			[settingKey] = value,
		},
	})
	SettingsServer.playerSettings[player.UserId][settingKey] = value
end

function SettingsServer.init()
	local conditions = {}
	for _, v in script.Conditions:GetChildren() do
		conditions[v.Name] = require(v)
	end

	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		SettingsServer.playerSettings[player.UserId] = {}
		for i, v in SharedData.Settings do
			SettingsServer.playerSettings[player.UserId][i] = v.Default
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		SettingsServer.playerSettings[player.UserId] = nil
	end)

	Net:Connect("SetSettingAttempt", function(player: Player, settingName: string, value: any)
		assert(settingName and typeof(settingName) == "string", "Sent setting name was not of type string")

		local settingData = SharedData.Settings[settingName]
		assert(settingData, settingName .. " was not found in settings data")

		local serverConditions = settingData.ServerConditions
		if serverConditions then
			for _, v in serverConditions do
				if conditions[v] then
					if not conditions[v](player, settingName, value, settingData) then
						return
					end
				end
			end
		end

		SettingsServer.SetSettingForPlayer(player, settingName, value)
	end)
	Net:Handle("GetPlayersSettings", function()
		return SettingsServer.playerSettings
	end)
end

return SettingsServer
