local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local Net = require(ReplicatedStorage.Packages.Net)

local IndexServer = {}
IndexServer.unlockedNewCharacters = Net:RemoteEvent("UnlockedNewCharacters")

function IndexServer.init()
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local profileData = PlayerDataServer.GetPlayerProfileData(player)
		local unlockedCharacters = profileData.UnlockedCharacters
		if #unlockedCharacters > 0 then
			IndexServer.unlockedNewCharacters:FireClient(player, unlockedCharacters)
		end
	end)
end

return IndexServer
