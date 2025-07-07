local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedData = require(script.Parent.Data)

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)

local scoped, peek = Fusion.scoped, Fusion.peek

local PlayerDataServer = {
	data = SharedData,
}
PlayerDataServer.PlayerProfileLoaded = Signal.new()

function PlayerDataServer.GetPlayerProfile(player: Player): ProfileStore.Profile<SharedData.PlayerDataTemplate>?
	local profile = PlayerDataServer.Profiles[player]
	if not profile then
		warn(player.Name .. "'s profile hasnt loaded")
	end
	return profile
end

function PlayerDataServer.AddToLeaderstat(player: Player, statName: string, amount: number)
	local profile = PlayerDataServer.GetPlayerProfile(player)
	if profile then
		profile.Data.Leaderstats[statName] += amount
		player:FindFirstChild("leaderstats"):FindFirstChild(statName).Value += amount
	end
end

function PlayerDataServer.init(): ()
	local PlayerStore = ProfileStore.New("PlayerStore", SharedData.Template)
	local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}
	PlayerDataServer.Profiles = Profiles

	local playerScopes = {}
	Players.PlayerAdded:Connect(function(player)
		local scope = scoped(Fusion)
		playerScopes[player] = scope

		local leaderstatValues = scope:Value({})
		scope:New("Folder")({
			Name = "leaderstats",
			Parent = player,
			[Fusion.Children] = leaderstatValues,
		})

		local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

			profile.OnSessionEnd:Connect(function()
				Profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)

			if player.Parent == Players then
				Profiles[player] = profile
				for i, v in profile.Data.Leaderstats do
					local state = table.clone(peek(leaderstatValues))
					table.insert(
						state,
						scope:New("NumberValue")({
							Name = i,
							Value = v,
						})
					)
					leaderstatValues:set(state)
				end
				player:SetAttribute("ProfileLoaded", true)
				PlayerDataServer.PlayerProfileLoaded:Fire(player)
			else
				profile:EndSession()
			end
		else
			-- This condition should only happen when the Roblox server is shutting down
			player:Kick(`Profile load fail - Please rejoin`)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if playerScopes[player] then
			playerScopes[player]:doCleanup()
		end

		local profile = Profiles[player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)
end

return PlayerDataServer
