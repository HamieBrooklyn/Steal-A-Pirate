local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local innerScope = Fusion.innerScope

local Step = {}
Step.__index = Step

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	text: Fusion.Value<string, any>,

	ended: Signal.Signal,
}
export type Step = typeof(setmetatable({} :: self, Step))

function Step.new(scope: Fusion.Scope<any>, text: Fusion.Value<string, any>, ...): Step
	local self = setmetatable({}, Step) :: Step

	self.scope = innerScope(scope)
	self.trove = Trove.new()

	self.text = text

	self.ended = Signal.new()
	self.trove:Add(self.ended)

	return self
end

function Step.Started(self: Step, ...)
	self.text:set("Some information")
end

function Step.Destroy(self: Step): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Step
