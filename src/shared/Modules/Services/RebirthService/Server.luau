local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedSpawningData = require(Services.SpawningService.Data)
local SharedData = require(script.Parent.Data)

local PlayerDataServer = require(Services.PlayerDataService.Server)
local SpawningServer = require(Services.SpawningService.Server)
local BaseServer = require(Services.BaseService.Server)

local PlayerDataTypes = PlayerDataServer.data

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local peek = Fusion.peek

local RebirthServer = {
	RebirthDataLoaded = Net:RemoteEvent("RebirthDataLoaded"),
	SharedData = SharedData,
}

function RebirthServer.init()
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local profileData: PlayerDataTypes.PlayerDataTemplate = PlayerDataServer.GetPlayerProfile(player).Data
		if profileData.RebirthSeed == 0 then
			profileData.RebirthSeed = os.time()
		end
		RebirthServer.RebirthDataLoaded:FireClient(
			player,
			tostring(profileData.RebirthSeed),
			profileData.Leaderstats.Rebirths
		)
	end)
	Net:Handle("GetRebirthData", function(player: Player)
		local profile = PlayerDataServer.Profiles[player]
		if not profile then
			return
		end
		return tostring(profile.Data.RebirthSeed), profile.Data.Leaderstats.Rebirths
	end)
	Net:Handle("RebirthAttempt", function(player)
		local profile = PlayerDataServer.GetPlayerProfile(player)
		if not profile then
			return
		end
		local base = BaseServer.GetPlayerBase(player)
		if not base then
			return
		end

		local rebirths = profile.Data.Leaderstats.Rebirths
		local rebirthSeed = profile.Data.RebirthSeed + rebirths

		local rnd = Random.new(rebirthSeed)

		local function obtainable(charName: string)
			return SharedSpawningData.Characters.Info[charName].Natural == true
				or SharedSpawningData.Characters.Info[charName].Natural == nil
		end

		local rebirthLevelData = SharedData.Levels[rebirths + 1]
		if rebirthLevelData then
			assert(profile.Data.Leaderstats.Cash >= rebirthLevelData.CashRequired, "Player didnt have enough Cash")

			local charactersLeft = {}
			for _, v in rebirthLevelData.Characters do
				local charactersWithRarity = SpawningServer.characterNamesByRarity[v]

				local tries = 0
				local charName: string
				repeat
					charName = charactersWithRarity[rnd:NextInteger(1, #charactersWithRarity)]
					tries += 1
				until obtainable(charName) and (table.find(charactersLeft, charName) == nil or tries > 100)

				table.insert(charactersLeft, charName)
			end
			for _, v in base.Platforms do
				local i = table.find(charactersLeft, peek(v.CharacterName))
				if i then
					table.remove(charactersLeft, i)
				end
			end
			assert(#charactersLeft == 0, "Player didnt have all characters")
		end

		base:ResetAllPlatforms(true)

		PlayerDataServer.UpdateLeaderstat(player, "Rebirths", 1)
		local earnings = SharedData.Constants.StartingCash * profile.Data.Leaderstats.Rebirths
		PlayerDataServer.SetLeaderstat(player, "Cash", earnings)
		PlayerDataServer.GetPlayerProfileData(player).TotalEarnings += earnings

		for _, spawner in SpawningServer.spawners do
			for _, v in spawner.SpawnedCharacters do
				if peek(v.Player) == player then
					v.Player:set(nil)
				end
			end
		end

		return true
	end)
end

return RebirthServer
