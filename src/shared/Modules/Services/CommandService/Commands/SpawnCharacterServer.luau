local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpawningService = ReplicatedStorage.Shared.Modules.Services.SpawningService

local SharedSpawningData = require(SpawningService.Data)

local SpawningServer = require(SpawningService.Server)

return function(context, name: string, amount: number?, cooldown: number?)
	amount = amount or 1
	cooldown = cooldown or 0.01
	if not SharedSpawningData.Characters.Info[name] then
		return name .. " was not found as a character data, maybe spelt wrong?"
	end
	task.spawn(function()
		for i = 1, amount do
			SpawningServer.spawners[SpawningServer.portalIdsByName["MainPortals"]]:SpawnCharacter(name)
			task.wait(cooldown)
		end
	end)
	return "Spawned " .. amount .. " " .. name .. "!"
end
