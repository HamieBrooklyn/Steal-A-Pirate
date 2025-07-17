local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local atom, subscribe = Charm.atom, Charm.subscribe

local Step = require(script.Parent.Steps.Step)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Quest = {}
Quest.__index = Quest

type self = {
	player: Player,

	questName: string,

	steps: { Step.Step },
	stepsInfo: { { stepName: string, texts: { [string]: string }, parameters: { any } } },
	stepAtom: Charm.Atom<number>,

	_trove: Trove.Trove,
	_questSteps: { [string]: Step.Step },
	_finishedCallback: (() -> ())?,
	_ignoreSaveUponCompletion: boolean,
}
export type Quest = typeof(setmetatable({} :: self, Quest))

function Quest.new(
	player: Player,
	questName: string,
	questSteps: { [string]: Step.Step },
	stepStarted: (stepName: string, texts: { [string]: string }, ...any) -> (),
	stepFinished: (stepName: string, texts: { [string]: string }, ...any) -> (),
	finished: (save: boolean) -> ()
): Quest
	local self = setmetatable({}, Quest) :: Quest

	self._trove = Trove.new()

	self.questName = questName

	self.player = player
	self.steps = {}
	self.stepsInfo = {}
	self.stepAtom = atom(0)
	self._trove:Add(subscribe(self.stepAtom, function(state: number)
		if state <= #self.steps then
			local stepInfo = self.stepsInfo[state]
			stepStarted(stepInfo.stepName, stepInfo.texts, stepInfo.parameters)
			task.spawn(function()
				self.steps[state]:Start(function()
					self.steps[state]:Clean()
					stepFinished(stepInfo.stepName, stepInfo.texts, stepInfo.parameters)
					stepInfo.finished()
					task.wait(1)
					self:Progress()
				end, self.player, stepInfo.texts, table.unpack(stepInfo.parameters))
			end)
		else
			if self._finishedCallback then
				self._finishedCallback()
			end
			finished(self._ignoreSaveUponCompletion)
			self:Cleanup()
		end
	end))

	self._questSteps = questSteps

	return self
end

function Quest.NewStep(
	self: Quest,
	info: { stepName: string, texts: { [string]: string }, finished: (() -> ())? },
	...
): Quest
	local step = self._questSteps[info.stepName].new(self.player, info.texts, ...)
	table.insert(self.steps, step)
	table.insert(self.stepsInfo, {
		stepName = info.stepName,
		texts = info.texts,
		finished = info.finished,
		parameters = { ... },
	})
	return self
end

function Quest.Progress(self: Quest)
	self.stepAtom(self.stepAtom() + 1)
end

function Quest.Start(self: Quest, finished: () -> (), ignoreSaveUponCompletion: boolean?): Quest
	self._finishedCallback = finished
	self._ignoreSaveUponCompletion = ignoreSaveUponCompletion == true

	self:Progress()
	return self
end

function Quest.Cleanup(self: Quest): ()
	self._trove:Destroy()
end

return Quest
