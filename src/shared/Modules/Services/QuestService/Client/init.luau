local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Steps = script.Steps

local Quest = require(script.Quest)
local Step = require(Steps.Step)
local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)

local QuestClient = {
	stepClasses = {} :: { Step.Step },
}

function QuestClient.AddQuest()
	return Quest.new(QuestClient.stepClasses)
end

function QuestClient.init()
	for _, v in Steps:GetChildren() do
		if v:IsA("ModuleScript") then
			QuestClient.stepClasses[v.Name] = require(v)
		end
	end

	Observers.observeAttribute(Players.LocalPlayer, "IsInTutorial", function(value)
		if value then
			task.wait(1)
			QuestClient.AddQuest()
				:AddStep("BuyCharacter", "MainPortals", "Weak Loafy", {
					[1] = "Follow the arrows and recruit your first pirate!",
				})
				:AddStep("RetrieveCharacter", "Weak Loafy", {
					[1] = "Wait for the pirate to reach your base",
				})
				:AddStep("CollectFromCharacter", "Weak Loafy", {
					[1] = "Collect cash earned by your pirate",
				})
				:AddStep("TimedMessage", "Steal pirates from other players! Good luck.")
				:Start()
		end
	end)
end

return QuestClient
