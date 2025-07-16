local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedData = require(script.Parent.Data)

local SettingsMenu = require(script.SettingsMenu)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local New, Children, Value = Fusion.New, Fusion.Children, Fusion.Value
local scoped = Fusion.scoped

local SettingsClient = {
	playerSettings = {} :: { { [string]: Fusion.Value<any, any> } },
}
SettingsClient.getPlayersSettings = Net:RemoteFunction("GetPlayersSettings")
SettingsClient.setSettingAttempt = Net:RemoteEvent("SetSettingAttempt")

function SettingsClient.init()
	local conditions = {}
	for _, v in script.Conditions:GetChildren() do
		conditions[v.Name] = require(v)
	end

	local scope = scoped(Fusion)
	local function updateSettings(data: { [string]: { [string]: boolean } })
		for userId, setSettings in data do
			userId = tonumber(userId)
			for settingName, value in setSettings do
				if not SettingsClient.playerSettings[userId] then
					SettingsClient.playerSettings[userId] = {}
				end
				if SettingsClient.playerSettings[userId][settingName] then
					SettingsClient.playerSettings[userId][settingName]:set(value)
				else
					SettingsClient.playerSettings[userId][settingName] = Value(scope, value)
				end
			end
		end
	end
	Net:Connect("PlayersSettingsWasSet", updateSettings)
	Net:Connect("ProfileLoaded", function()
		updateSettings(SettingsClient.getPlayersSettings:InvokeServer())

		SettingsClient.screenGui = New(scope, "ScreenGui")({
			Name = "Settings",
			ResetOnSpawn = false,
			Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
			[Children] = SettingsMenu(scope, {
				settingsData = SharedData.Settings,
				playerSettings = SettingsClient.playerSettings[Players.LocalPlayer.UserId],
				setSetting = function(settingName: string, ...)
					local settingData = SharedData.Settings[settingName]
					if settingData.ClientConditions then
						for i, v in settingData.ClientConditions do
							if not conditions[v](i, settingName, settingData) then
								return
							end
						end
					end
					-- TODO: Client functionality types
					SettingsClient.setSettingAttempt:FireServer(settingName, ...)
				end,
			}),
		}) :: ScreenGui
		SettingsClient.screenGui:AddTag("Menu")
	end)
end

return SettingsClient
