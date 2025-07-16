local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local atom, subscribe = Charm.atom, Charm.subscribe

local Step = require(script.Parent.Steps.Step)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Quest = {}
Quest.__index = Quest

type self = {
	player: Player,

	steps: { Step.Step },
	stepsInfo: { { stepName: string, texts: { [string]: string }, parameters: { any } } },
	stepAtom: Charm.Atom<number>,

	_trove: Trove.Trove,
	_questSteps: { [string]: Step.Step },
}
export type Quest = typeof(setmetatable({} :: self, Quest))

function Quest.new(
	player: Player,
	questSteps: { [string]: Step.Step },
	stepStarted: (stepName: string, texts: { [string]: string }, ...any) -> (),
	stepFinished: (stepName: string, texts: { [string]: string }, ...any) -> ()
): Quest
	local self = setmetatable({}, Quest) :: Quest

	self._trove = Trove.new()

	self.player = player
	self.steps = {}
	self.stepsInfo = {}
	self.stepAtom = atom(0)
	self._trove:Add(subscribe(self.stepAtom, function(state, prev)
		if state <= #self.steps then
			local stepInfo = self.stepsInfo[state]
			stepStarted(stepInfo.stepName, stepInfo.texts, stepInfo.parameters)
			task.spawn(function()
				self.steps[state]:Start(function()
					stepFinished(stepInfo.stepName, stepInfo.texts, stepInfo.parameters)
					self:Progress()
				end, self.player, stepInfo.texts, table.unpack(stepInfo.parameters))
			end)
		else
			print("quest finished")
		end
	end))

	self._questSteps = questSteps

	return self
end

function Quest.NewStep(self: Quest, stepName: string, texts: { [string]: string }, ...): Quest
	local step = self._questSteps[stepName].new(self.player, texts, ...)
	table.insert(self.steps, step)
	table.insert(self.stepsInfo, {
		stepName = stepName,
		texts = texts,
		parameters = { ... },
	})
	return self
end

function Quest.Progress(self: Quest)
	self.stepAtom(self.stepAtom() + 1)
end

function Quest.Start(self: Quest): Quest
	self:Progress()
	return self
end

function Quest.Destroy(self: Quest): () end

return Quest
