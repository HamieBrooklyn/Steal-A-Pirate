local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spawnDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.spawnDescendants)

spawnDescendants(ReplicatedStorage.Shared.Modules.Services, "init", "Client")
