local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped = Fusion.scoped

local player = Players.LocalPlayer

local RebirthClient = {
	GetRebirthData = Net:RemoteFunction("GetRebirthData"),
}

function RebirthClient.init()
	local scope = scoped(Fusion)
	RebirthClient.rebirths = scope:Value(0) :: Fusion.Value<number, any>

	local menu = require(script.RebirthMenu).new(
		player:WaitForChild("PlayerGui"):WaitForChild("Rebirths"),
		RebirthClient.rebirths
	)

	local function loadMenuData(seed: string, rebirths: number)
		if seed and rebirths then
			local rebirthVal: NumberValue = player:WaitForChild("leaderstats"):WaitForChild("Rebirths")
			Observers.observeProperty(rebirthVal, "Value", function(value)
				RebirthClient.rebirths:set(rebirthVal.Value)
				return function() end
			end)

			menu.rootSeed:set(tonumber(seed))
			menu.BeliVal:set(player:WaitForChild("leaderstats"):WaitForChild("Beli"))
		end
	end
	Net:Connect("RebirthDataLoaded", loadMenuData)
	loadMenuData(RebirthClient.GetRebirthData:InvokeServer())
end

return RebirthClient
