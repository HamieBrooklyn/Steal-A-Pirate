local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tools = script.Tools

local Observers = require(ReplicatedStorage.Packages.Observers)
local Trove = require(ReplicatedStorage.Packages.Trove)

local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)

local ToolServer = {
	playerTools = {} :: { [string]: { [Tool]: any } },
}

function ToolServer.init()
	local toolClasses = {}
	for _, v in Tools:GetChildren() do
		if v:IsA("ModuleScript") then
			toolClasses[v.Name] = require(v)
		end
	end

	Observers.observeCharacter(function(player)
		local trove = Trove.new()

		ToolServer.playerTools[player.UserId] = {}

		trove:Add(observeChildren(player.Backpack, function(child: Instance)
			local toolClass = toolClasses[child.Name]
			if not child:IsA("Tool") or not toolClass or ToolServer.playerTools[player.UserId][child] then
				return
			end

			local tool = toolClass.new(player, child)
			ToolServer.playerTools[player.UserId][child] = tool

			return function()
				tool:Destroy()
				if ToolServer.playerTools[player.UserId] then
					ToolServer.playerTools[player.UserId][child] = nil
				end
			end
		end))

		return function()
			ToolServer.playerTools[player.UserId] = nil
			trove:Destroy()
		end
	end)
end

return ToolServer
