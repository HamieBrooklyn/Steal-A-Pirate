local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local scoped, peek = Fusion.scoped, Fusion.peek

local AnimatedHighlight = {}
AnimatedHighlight.__index = AnimatedHighlight

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,
	tempTrove: Trove.Trove,

	enabled: Fusion.Value<boolean, any>,
	pulseLooping: Fusion.Value<boolean, any>,
	parent: Fusion.Value<Instance?, any>,
	adornee: Fusion.Value<Instance?, any>,

	highlightInstance: Fusion.Value<Highlight, any>,

	startTransparency: Fusion.Value<number, any>,
	transparencySpring: Fusion.Spring<number>,
}
export type AnimatedHighlight = typeof(setmetatable({} :: self, AnimatedHighlight))

function AnimatedHighlight.new(
	props: { [string]: any },
	startParent: Instance?,
	startAdornee: Instance?
): AnimatedHighlight
	local self = setmetatable({}, AnimatedHighlight) :: AnimatedHighlight

	props = props or {}

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.enabled = self.scope:Value(false)
	self.pulseLooping = self.scope:Value(false)
	self.parent = self.scope:Value(startParent)
	self.adornee = self.scope:Value(startAdornee)

	self.startTransparency = self.scope:Value(1)
	self.transparencySpring = self.scope:Spring(self.startTransparency, 10, 1)

	self.highlightInstance = self.scope:Value(nil)

	self.tempTrove = Trove.new()
	self.trove:Add(self.tempTrove)

	local loopCon: RBXScriptConnection
	self.scope:Observer(self.pulseLooping):onChange(function()
		if loopCon then
			loopCon:Disconnect()
			loopCon = nil
		end
		if not peek(self.pulseLooping) then
			return
		end

		local lastPulse = time()
		loopCon = self.trove:Add(RunService.Heartbeat:Connect(function()
			if time() - lastPulse > 1 then
				lastPulse = time()
				self:Pulse()
			end
		end))
	end)
	self.scope:Observer(self.enabled):onChange(function()
		self.tempTrove:Clean()
		if not peek(self.enabled) then
			return
		end

		local hl: Highlight = self.tempTrove:Add(self.scope:New("Highlight")({
			Name = "AnimatedHighlight",

			FillTransparency = self.transparencySpring,
			OutlineTransparency = self.transparencySpring,

			Adornee = self.adornee,
			Parent = self.parent,
		}))
		for i, v in props do
			hl[i] = v
		end

		local started = time()
		self.tempTrove:Add(RunService.Heartbeat:Connect(function()
			if time() - started > 0.5 then
				self.enabled:set(false)
			end
		end))
	end)

	return self
end

function AnimatedHighlight.Pulse(self: AnimatedHighlight, targetTransparency: number?)
	self.tempTrove:Clean()

	self.enabled:set(true)
	self.transparencySpring:setVelocity(targetTransparency or -15)
end

function AnimatedHighlight.Destroy(self: AnimatedHighlight): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return AnimatedHighlight
