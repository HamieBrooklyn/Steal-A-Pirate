local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local spawnDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.spawnDescendants)

spawnDescendants(ReplicatedStorage.Shared.Modules.Services, "init", "Server")
--spawnDescendants(ServerScriptService.Server.Services, "init", "Server")
