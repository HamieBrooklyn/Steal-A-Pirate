local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SuccessSound = ReplicatedStorage.Assets.Sounds.SoundEffects.QuestSuccess

local Steps = script.Parent.Steps

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local QuestLabel = require(script.QuestLabel)
local Step = require(Steps.Step)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Children = Fusion.Children
local scoped, peek = Fusion.scoped, Fusion.peek

local Quest = {}
Quest.__index = Quest

type self = {
	scope: Fusion.Scope<any>,

	completed: Signal.Signal,

	trove: Trove.Trove,
	tempTrove: Trove.Trove,
	stepTrove: Trove.Trove,

	storedParameters: { [Step.Step]: { any } },

	stepClasses: { Step.Step },
	steps: Fusion.Value<Step.Step, any>,

	text: Fusion.Value<string, any>,

	paused: Fusion.Value<boolean, any>,
}
export type Quest = typeof(setmetatable({} :: self, Quest))

function Quest.new(stepClasses: { Step.Step }): Quest
	local self = setmetatable({}, Quest) :: Quest

	self.scope = scoped(Fusion, {
		QuestLabel = QuestLabel,
	})
	self.trove = Trove.new()
	self.tempTrove = self.trove:Add(Trove.new()) :: Trove.Trove
	self.stepTrove = self.tempTrove:Add(Trove.new()) :: Trove.Trove

	self.completed = self.trove:Add(Signal.new()) :: Signal.Signal

	self.storedParameters = {}

	self.stepClasses = stepClasses
	self.steps = self.scope:Value({})

	self.text = self.scope:Value("")

	self.currentStep = self.scope:Value(nil)
	self.trove:Add(self.scope:Observer(self.currentStep):onChange(function()
		self.stepTrove:Clean()
		local step: Step.Step? = peek(self.currentStep)
		if not step then
			return
		end
		self.stepTrove:Add(self.scope:Observer(step.text):onBind(function()
			self.text:set(peek(step.text))
		end))
	end))

	self.scope:New("ScreenGui")({
		Name = "Quest",
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
		[Children] = self.scope:QuestLabel({
			text = self.text,
		}),
	})

	self.paused = self.scope:Value(true)
	self.trove:Add(self.scope:Observer(self.paused):onChange(function()
		self.tempTrove:Clean()
		if peek(self.paused) then
			return
		end
		self.tempTrove:Add(self.scope:Observer(self.steps):onBind(function()
			local step: Step.Step? = peek(self.steps)[1]
			if step then
				self.currentStep:set(step)
				task.spawn(function()
					task.spawn(function()
						step:Started(table.unpack(self.storedParameters[step]))
					end)
					step.ended:Once(function()
						Sound.new(SuccessSound):Play()

						step:Destroy()
						self.text:set("")

						task.delay(1, function()
							local state = table.clone(peek(self.steps))
							table.remove(state, table.find(state, step))
							self.steps:set(state)
						end)
					end)
				end)
			else
				self.completed:Fire()
				self:Destroy()
			end
		end))
	end))

	return self
end

function Quest.Start(self: Quest): Quest
	self.paused:set(false)
	return self
end

function Quest.AddStep(self: Quest, stepKey: string, ...): Quest
	local step = self.stepClasses[stepKey].new(self.scope, self.text, ...)
	self.storedParameters[step] = { ... }

	local state = table.clone(peek(self.steps))
	table.insert(state, step)
	self.steps:set(state)

	return self
end

function Quest.Destroy(self: Quest): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Quest
