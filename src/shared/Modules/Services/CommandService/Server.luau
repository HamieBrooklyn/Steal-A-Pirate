local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

local CommandServer = {}

function CommandServer.init()
	Cmdr:RegisterDefaultCommands({ "DefaultAdmin", "DefaultDebug", "Help" })
	Cmdr:RegisterCommandsIn(script.Parent.Commands)
end

return CommandServer
