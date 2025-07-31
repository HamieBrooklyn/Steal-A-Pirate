local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local BaseServer = require(Services.BaseService.Server)

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)
local Spawner = require(script.Spawner)

local createTaggedComponent = require(ReplicatedStorage.Shared.Modules.Utilities.createTaggedComponent)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Net = require(ReplicatedStorage.Packages.Net)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

local SpawningServer = {
	spawners = {} :: { [string]: Spawner.Spawner },
	characterNamesByRarity = {} :: { [string]: { string } },
}
SpawningServer.updatePlayerChachedSpawns = Net:RemoteEvent("CachedSpawnsUpdated")

function SpawningServer.AddGuaranteedCharacterToSpawner(spawnerName: string, characterName: string)
	table.insert(
		SpawningServer.spawners[SpawningServer.spawnerIdsByName[spawnerName]].guaranteedSpawnsQueue,
		characterName
	)
end

function SpawningServer.AddCachedSpawnForPlayer(player: Player, pirateName: string)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if playerProfile then
		table.insert(playerProfile.Data.CachedSpawns, pirateName)
		SpawningServer.updatePlayerChachedSpawns:FireClient(player, playerProfile.Data.CachedSpawns)
	end
end

function SpawningServer.init()
	SpawningServer.spawnerIdsByName = {} :: { [string]: string }

	for i: string, v: SharedTypes.CharacterData in SharedData.Characters.Info do
		if not SpawningServer.characterNamesByRarity[v.Rarity] then
			SpawningServer.characterNamesByRarity[v.Rarity] = {}
		end
		table.insert(SpawningServer.characterNamesByRarity[v.Rarity], i)
	end
	for _, v in SpawningServer.characterNamesByRarity do
		table.sort(v, function(a, b)
			return a < b
		end)
	end

	-- Net:Handle("GetGuaranteedSpawnsInfo", function(_player, spawnerId: string)
	-- 	assert(spawnerId and typeof(spawnerId) == "string", "Sent spawner id was not of type string")

	-- 	local spawner = SpawningServer.spawners[spawnerId]
	-- 	assert(spawner, spawnerId .. " was not a valid spawner id")

	-- 	local info = {}
	-- 	for i, v in spawner.lastGuaranteedRaritySpawn do
	-- 		info[i] = tostring(v)
	-- 	end
	-- 	return info
	-- end)

	Observers.observeTag("DontCollideWithPirate", function(instance)
		local savedGroup = {}
		if instance:IsA("BasePart") then
			savedGroup[instance] = instance.CollisionGroup
			instance.CollisionGroup = "PiratePassthrough"
		end
		for _, v in instance:GetDescendants() do
			if v:IsA("BasePart") then
				savedGroup[v] = v.CollisionGroup
				v.CollisionGroup = "PiratePassthrough"
			end
		end
		return function()
			for i, v in savedGroup do
				i.CollisionGroup = v
			end
		end
	end)
	Observers.observeTag(SharedData.Spawning.Tag, function(instance)
		local data = SharedData.Spawning.Spawners[instance.Name]
		if not data then
			warn(instance.Name .. " did not have a data table")
			return
		end
		local spawner = Spawner.new(instance, data)
		SpawningServer.spawnerIdsByName[instance.Name] = spawner.id
		SpawningServer.spawners[spawner.id] = spawner
		return function()
			if SpawningServer.spawners[spawner.id] then
				SpawningServer.spawners[spawner.id] = nil
			end
			SpawningServer.spawnerIdsByName[instance.Name] = nil
			spawner:Destroy()
		end
	end)
	local lastCheckTime = time()
	RunService.Heartbeat:Connect(function()
		if time() - lastCheckTime < 1 then
			return
		end
		lastCheckTime = time()

		for _, v in SpawningServer.spawners do
			v:Heartbeat()
		end
	end)
	createTaggedComponent("Mutated", require(script.Mutated))

	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if #playerProfile.Data.CachedSpawns > 0 then
			SpawningServer.updatePlayerChachedSpawns:FireClient(player, playerProfile.Data.CachedSpawns)
		end
	end)
	Net:Handle("GetCachedSpawns", function(player)
		local playerProfile = PlayerDataServer.Profiles[player]
		if playerProfile then
			return playerProfile.Data.CachedSpawns
		end
	end)
	Net:Handle("SpawnCachedPirate", function(player, pirateName: string)
		local base = BaseServer.GetPlayerBase(player)
		if not base then
			return false
		end
		assert(not peek(base.BaseFull), `{player.Name}'s base was full`)

		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if not playerProfile then
			return false
		end

		local i: number? = table.find(playerProfile.Data.CachedSpawns, pirateName)
		assert(i ~= nil, `{player.Name} did not have {pirateName} in their cached spawns`)

		table.remove(playerProfile.Data.CachedSpawns, i)

		base:AddCharacter(player, pirateName)

		return true
	end)
end

return SpawningServer
