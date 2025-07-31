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

	local BaseServer = require(Services.BaseService.Server)
	Net:Connect("DisplayCharacterAttempt", function(player: Player, pirateName: string)
		assert(pirateName and typeof(pirateName) == "string", "Sent pirate name was not of type string")

		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if not playerProfile then
			return
		end
		assert(
			table.find(playerProfile.Data.UnlockedCharacters, pirateName) ~= nil,
			`{player.Name} did not own {pirateName}`
		)

		local base = BaseServer.GetPlayerBase(player)
		if base then
			playerProfile.Data.PirateOnDisplay = pirateName
			base.pirateOnDisplay(pirateName)
		end
	end)
end

return IndexServer
