local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services
local Tools = script.Tools

local PlayerDataClient = require(Services.PlayerDataService.Client)

local Data = require(script.Parent.Data)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)

local scoped = Fusion.scoped

local player = Players.LocalPlayer

local ToolClient = {
	sharedData = Data,
	playerTools = {} :: { [Instance]: any },
}
ToolClient.BuyToolAttempt = Net:RemoteEvent("BuyToolAttempt")

function ToolClient.init()
	local toolClasses = {}
	for _, v in Tools:GetChildren() do
		if v:IsA("ModuleScript") then
			toolClasses[v.Name] = require(v)
		end
	end

	local scope = scoped(Fusion, {
		ToolShop = require(script.ToolShop),
	})

	PlayerDataClient.LeaderstatsLoaded:Once(function()
		scope:ToolShop({
			buyToolAttempt = ToolClient.BuyToolAttempt,
		})
	end)

	observeCharacter(player, function(_char)
		local trove = Trove.new()

		trove:Add(observeChildren(player.Backpack, function(child: Instance)
			local funcName = child:GetAttribute("Functionality")
			local toolClass = toolClasses[child.Name] or (funcName and toolClasses[funcName])
			if not child:IsA("Tool") or not toolClass or ToolClient.playerTools[child] then
				return
			end

			local tool = toolClass.new(child)
			ToolClient.playerTools[child] = tool

			return function()
				if ToolClient.playerTools then
					ToolClient.playerTools[child] = nil
				end
				tool:Destroy()
			end
		end))

		return function()
			trove:Destroy()
		end
	end)
end

return ToolClient
