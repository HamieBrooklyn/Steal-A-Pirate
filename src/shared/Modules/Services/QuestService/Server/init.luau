local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local PopupServer = require(Services.PopupService.Server)

local Quest = require(script.Quest)
local Step = require(script.Steps.Step)

local Net = require(ReplicatedStorage.Packages.Net)

local stepStarted = Net:RemoteEvent("QuestStepStarted")
local stepFinished = Net:RemoteEvent("QuestStepFinished")

local questSteps = {} :: { [string]: Step.Step }

local QuestServer = {
	playerQuests = {} :: { Quest.Quest },
}

function QuestServer.StartQuest(player: Player, questName: string): Quest.Quest?
	if not QuestServer.playerQuests[player.UserId] then
		local quest = Quest.new(player, questName, questSteps, function(stepName, info, ...)
			stepStarted:FireClient(player, stepName, info, ...)
		end, function(stepName, info, ...)
			stepFinished:FireClient(player, stepName, info, ...)
		end, function(ignoreSave)
			if ignoreSave then
				return
			end
			local playerProfile = PlayerDataServer.GetPlayerProfile(player)
			if playerProfile then
				table.insert(playerProfile.Data.CompletedQuests, questName)
			end
		end)
		QuestServer.playerQuests[player.UserId] = quest
		return quest
	else
		PopupServer.SendPopupTo(player, {
			message = "Finish your current quest first!",
			gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Banana,
		})
	end
end

function QuestServer.init()
	for _, v in script.Steps:GetChildren() do
		questSteps[v.Name] = require(v)
	end

	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if not table.find(playerProfile.Data.CompletedQuests, "Tutorial") then
			local quest = QuestServer.StartQuest(player, "Tutorial")
			if quest then
				quest
					:NewStep({
						stepName = "BuyCharacter",
						texts = { ["Main"] = "Follow the arrows and recruit your first pirate" },
						finished = function()
							print("here1")
							AnalyticsService:LogFunnelStepEvent(
								player,
								"Tutorial",
								_G.funnelSessionId,
								1,
								"Recruit first character"
							)
						end,
					}, "Main Portals", "Weak Loafy")
					:NewStep({
						stepName = "GetCharacterToBase",
						texts = { ["Main"] = "Wait for the pirate to reach your base" },
						finished = function()
							print("here2")
							AnalyticsService:LogFunnelStepEvent(
								player,
								"Tutorial",
								_G.funnelSessionId,
								2,
								"Wait for pirate to get to base"
							)
						end,
					}, "Weak Loafy")
					:NewStep({
						stepName = "CollectPlatform",
						texts = { ["Main"] = "Collect cash earned by your pirate" },
						finished = function()
							print("here3")
							AnalyticsService:LogFunnelStepEvent(
								player,
								"Tutorial",
								_G.funnelSessionId,
								3,
								"Collect the generated money"
							)
						end,
					}, "Weak Loafy")
					:NewStep({
						stepName = "TimedMessage",
						texts = { ["Main"] = "Steal pirates from other players! Good luck!" },
						finished = function()
							print("here4")
							AnalyticsService:LogFunnelStepEvent(
								player,
								"Tutorial",
								_G.funnelSessionId,
								4,
								"Wait for the last message"
							)
						end,
					}, 3)
					:Start(function()
						print("here5")
						AnalyticsService:LogFunnelStepEvent(
							player,
							"Tutorial",
							_G.funnelSessionId,
							5,
							"Completed tutorial"
						)
					end)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		if QuestServer.playerQuests[player.UserId] then
			print(QuestServer.playerQuests[player.UserId])
			QuestServer.playerQuests[player.UserId]:Cleanup()
			QuestServer.playerQuests[player.UserId] = nil
		end
	end)
end

return QuestServer
