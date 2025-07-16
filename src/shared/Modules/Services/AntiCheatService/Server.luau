local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sensors = require(ReplicatedStorage.Packages.Sensors)
local AntiCheatServer = {}

function AntiCheatServer.init()
	Sensors.createSensor({})
	Sensors.start()
end

return AntiCheatServer
