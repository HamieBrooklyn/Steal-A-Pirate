local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stealing = require(script.Stealing)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Net = require(ReplicatedStorage.Packages.Net)

local atom = Charm.atom

local PlayerServer = {
	players = {} :: { [string]: { Stealing: Stealing.Stealing, FriendBoostMult: Charm.Atom<number> } },
}
PlayerServer.updatePlayerFriendBoost = Net:RemoteEvent("FriendBoostUpdated")

PlayerServer.PlayerLoaded = Signal.new()

function PlayerServer.init()
	local HttpService = game:GetService("HttpService")
	_G.funnelSessionId = HttpService:GenerateGUID()

	local function checkFriendBoosts()
		for _, plr1: Player in Players:GetPlayers() do
			local boost = 1
			for _, plr2: Player in Players:GetPlayers() do
				if plr1 ~= plr2 and plr1:IsFriendsWith(plr2.UserId) then
					boost += 0.1
				end
			end
			PlayerServer.players[tostring(plr1.UserId)].FriendBoostMult(boost)
			PlayerServer.updatePlayerFriendBoost:FireClient(plr1, boost)
		end
	end
	Net:Handle("GetFriendBoost", function(player)
		return PlayerServer.players[tostring(player.UserId)].FriendBoostMult()
	end)
	Observers.observePlayer(function(player)
		local id = tostring(player.UserId)

		PlayerServer.players[id] = {
			Stealing = Stealing.new(player),
			FriendBoostMult = atom(1),
		}
		PlayerServer.PlayerLoaded:Fire(player)

		checkFriendBoosts()

		return function()
			checkFriendBoosts()

			PlayerServer.players[id].Stealing:RetrieveCurrentStolenItem()
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

		player.CharacterAppearanceLoaded:Connect(function()
			task.spawn(function()
				task.wait()
				for _, v in pairs(character:GetChildren()) do
					if v:IsA("CharacterMesh") then
						v:Destroy()
					end
				end
			end)
		end)

		return function()
			trove:Destroy()
		end
	end)
end

return PlayerServer
