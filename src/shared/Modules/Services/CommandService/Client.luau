local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

local CommandClient = {}

function CommandClient.init()
	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

return CommandClient
