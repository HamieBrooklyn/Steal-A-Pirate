local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedData = require(script.Parent.Data)
local Spawner = require(script.Spawner)

local Observers = require(ReplicatedStorage.Packages.Observers)

local SpawningServer = {
	spawners = {} :: { Spawner.Spawner },
}

function SpawningServer.init()
	Observers.observeTag(SharedData.Spawning.Tag, function(instance)
		local data = SharedData.Spawning.Spawners[instance.Name]
		if not data then
			warn(instance.Name .. " did not have a data table")
			return
		end
		local spawner = Spawner.new(instance, data)
		SpawningServer.spawners[instance.Name] = spawner
		return function()
			if SpawningServer.spawners[instance.Name] then
				SpawningServer.spawners[instance.Name] = nil
			end
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
