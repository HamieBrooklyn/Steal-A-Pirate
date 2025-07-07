local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local PlayerDataTypes = PlayerDataServer.data

local RebirthServer = {}

function RebirthServer.init()
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local profileData: PlayerDataTypes.PlayerDataTemplate = PlayerDataServer.GetPlayerProfile(player).Data
		if profileData.RebirthSeed == 0 then
			profileData.RebirthSeed = os.time()
		end
	end)
end

return RebirthServer
