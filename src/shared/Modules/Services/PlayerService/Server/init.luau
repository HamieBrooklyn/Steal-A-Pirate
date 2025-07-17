local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stealing = require(script.Stealing)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlayerServer = {
	players = {} :: { [string]: { Stealing: Stealing.Stealing } },
}
PlayerServer.PlayerLoaded = Signal.new()

function PlayerServer.init()
	local HttpService = game:GetService("HttpService")
	_G.funnelSessionId = HttpService:GenerateGUID()

	Observers.observePlayer(function(player)
		local id = tostring(player.UserId)

		PlayerServer.players[id] = {
			Stealing = Stealing.new(player),
		}
		PlayerServer.PlayerLoaded:Fire(player)

		return function()
			PlayerServer.players[id].Stealing:Destroy()
			PlayerServer.players[id] = nil
		end
	end)

	Observers.observeCharacter(function(player, character)
		local trove = Trove.new()
		local function descendantAdded(descendant: Instance)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = "Character"
			end
		end
		for _, v in character:GetDescendants() do
			descendantAdded(v)
		end
		trove:Add(character.DescendantAdded:Connect(descendantAdded))
		return function()
			trove:Destroy()
		end
	end)
end

return PlayerServer
