local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local Quest = require(script.Quest)
local Step = require(script.Steps.Step)

local Net = require(ReplicatedStorage.Packages.Net)

local stepStarted = Net:RemoteEvent("QuestStepStarted")
local stepFinished = Net:RemoteEvent("QuestStepFinished")

local questSteps = {} :: { [string]: Step.Step }

local QuestServer = {
	playerQuests = {} :: { Quest.Quest },
}

function QuestServer.StartQuest(player: Player): Quest.Quest?
	if not QuestServer.playerQuests[player.UserId] then
		local quest = Quest.new(player, questSteps, function(stepName, info, ...)
			stepStarted:FireClient(player, stepName, info, ...)
		end, function(stepName, info, ...)
			stepFinished:FireClient(player, stepName, info, ...)
		end)
		QuestServer.playerQuests[player.UserId] = quest
		return quest
	else
		print("already has quest")
	end
end

function QuestServer.init()
	for _, v in script.Steps:GetChildren() do
		questSteps[v.Name] = require(v)
	end

	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if not table.find(playerProfile.Data.CompletedQuests, "Tutorial") then
			QuestServer.StartQuest(player)
				:NewStep("BuyCharacter", { ["Main"] = "Follow the arrows and recruit your first pirate" }, "Weak Loafy")
				:Start()
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		QuestServer.playerQuests[player.UserId] = nil
	end)
end

return QuestServer
