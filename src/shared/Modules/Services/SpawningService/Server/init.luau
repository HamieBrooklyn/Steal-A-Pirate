local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)
local Spawner = require(script.Spawner)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Net = require(ReplicatedStorage.Packages.Net)

local SpawningServer = {
	spawners = {} :: { [string]: Spawner.Spawner },
	characterNamesByRarity = {} :: { [string]: { string } },
}

function SpawningServer.init()
	SpawningServer.portalIdsByName = {} :: { [string]: string }

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

	Net:Handle("GetGuaranteedSpawnsInfo", function(player, spawnerId: string)
		print(player, spawnerId)
		assert(spawnerId and typeof(spawnerId) == "string", "Sent spawner id was not of type string")

		local spawner = SpawningServer.spawners[spawnerId]
		assert(spawner, spawnerId .. " was not a valid spawner id")

		local info = {}
		for i, v in spawner.lastGuaranteedRaritySpawn do
			info[i] = tostring(v)
		end
		return info
	end)

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
		SpawningServer.portalIdsByName[instance.Name] = spawner.id
		SpawningServer.spawners[spawner.id] = spawner
		return function()
			if SpawningServer.spawners[spawner.id] then
				SpawningServer.spawners[spawner.id] = nil
			end
			SpawningServer.portalIdsByName[instance.Name] = nil
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
end

return SpawningServer
