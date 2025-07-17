local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestStepsMenu = require(script.QuestStepsMenu)
local Step = require(script.Steps.Step)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

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
	local stepTextShown = scope:Value(false)
	QuestStepsMenu(scope, {
		stepText = stepText,
		stepTextShown = stepTextShown,
	})

	local currentStep: Step.Step?
	Net:Connect("QuestStepStarted", function(stepName: string, texts: { [string]: string }, info: { any })
		currentStep = QuestClient.steps[stepName].new(stepText, texts, table.unpack(info))
		currentStep:Start(texts, table.unpack(info))
		stepTextShown:set(true)
	end)
	Net:Connect("QuestStepFinished", function(stepName: string, texts: { [string]: string }, info: { any })
		currentStep:Clean()
		currentStep = nil
		stepTextShown:set(false)
		Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.QuestSuccess, workspace):Play()
	end)
end

return QuestClient
