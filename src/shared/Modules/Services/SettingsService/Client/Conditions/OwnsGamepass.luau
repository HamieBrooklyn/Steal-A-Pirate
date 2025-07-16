local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local MonitizationClient = require(Services.MonitizationService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

local function OwnsGamepass(index: number, settingName: string, settingData: SharedTypes.SettingData): boolean
	local playerPasses = MonitizationClient.playerGamepasses[Players.LocalPlayer.UserId]
	if not playerPasses then
		return false
	end
	if playerPasses[settingName] == nil then
		return false
	end
	if peek(playerPasses[settingName]) == false then
		local id = MonitizationClient.data.Products[settingData.GamepassKeys[index]].Id
		MonitizationClient.PromptPurchase(id)
		return false
	end

	return true
end

return OwnsGamepass
