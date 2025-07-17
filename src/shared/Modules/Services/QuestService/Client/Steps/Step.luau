local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Step = {}
Step.__index = Step

type self = {
	currentText: Fusion.Value<string, any>,

	_trove: Trove.Trove,
}
export type Step = typeof(setmetatable({} :: self, Step))

function Step.new(currentText: Fusion.Value<string, any>, texts: { [string]: string }, ...): Step
	local self = setmetatable({}, Step) :: Step

	self._trove = Trove.new()

	self.currentText = currentText

	return self
end

function Step.Start(self: Step, texts: { [string]: string }, ...): () end

function Step.Clean(self: Step): ()
	self._trove:Destroy()
end

return Step
