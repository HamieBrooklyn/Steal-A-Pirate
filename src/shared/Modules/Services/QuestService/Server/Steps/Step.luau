local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local Step = {}
Step.__index = Step

type self = {
	_trove: Trove.Trove,
}
export type Step = typeof(setmetatable({} :: self, Step))

function Step.new(player: Player, texts: { [string]: string }, ...): Step
	local self = setmetatable({}, Step) :: Step

	self._trove = Trove.new()

	return self
end

function Step.Start(self: Step, finished: () -> (), player: Player, texts: { [string]: string }, ...): () end

function Step.Clean(self: Step): ()
	self._trove:Destroy()
end

return Step
