local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestStepsMenu = require(script.QuestStepsMenu)
local Step = require(script.Steps.Step)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local scoped = Fusion.scoped

export type Step = Step.Step

local QuestClient = {}

function QuestClient.init()
	QuestClient.steps = {} :: { [string]: Step.Step }
	for _, v in script.Steps:GetChildren() do
		QuestClient.steps[v.Name] = require(v)
	end

	local scope = scoped(Fusion)

	local stepText = scope:Value("")
	QuestStepsMenu(scope, {
		stepText = stepText,
	})
	local currentStep: Step.Step?
	Net:Connect("QuestStepStarted", function(stepName: string, texts: { [string]: string }, info: { any })
		currentStep = QuestClient.steps[stepName].new(stepText, texts, table.unpack(info))
		currentStep:Start(texts, table.unpack(info))
	end)
	Net:Connect("QuestStepFinished", function(stepName: string, texts: { [string]: string }, info: { any })
		currentStep:Clean()
		currentStep = nil
		stepText:set("")
	end)
end

return QuestClient
