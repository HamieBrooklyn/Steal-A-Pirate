local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(ReplicatedStorage.Packages.Trove)

local Particle = {}
Particle.__index = Particle

type self = {
	_trove: Trove.Trove,
	_completedConnection: RBXScriptConnection,

	Emitters: { ParticleEmitter },
}
export type Particle = typeof(setmetatable({} :: self, Particle))

function Particle.new(
	particle: ParticleEmitter | Attachment | BasePart,
	location: Instance | BasePart | Vector3 | CFrame
): Particle
	local self = setmetatable({}, Particle) :: Particle

	self._trove = Trove.new()

	self.DestroyOnFinish = false

	particle = particle:Clone()
	self._trove:Add(particle)

	self.Emitters = {}
	if particle:IsA("BasePart") or particle:IsA("Attachment") then
		for _, v in particle:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				table.insert(self.Emitters, v)
			end
		end
	elseif particle:IsA("ParticleEmitter") then
		table.insert(self.Emitters, particle)
	end
	self:SetEnabled(false)

	local part: Part?
	local cf: CFrame
	if typeof(location) == "Instance" then
		particle.Parent = location
		cf = location:GetPivot()
		if particle:IsA("BasePart") then
			particle:PivotTo(cf)
		elseif particle:IsA("ParticleEmitter") or particle:IsA("Attachment") then
			particle.Parent = location
		end
	elseif typeof(location) == "Vector3" or typeof(location) == "CFrame" then
		if particle:IsA("BasePart") then
			part = particle
		elseif particle:IsA("ParticleEmitter") or particle:IsA("Attachment") then
			part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Transparency = 1
		end
		cf = typeof(location) == "CFrame" and location or CFrame.new(location)
	end
	if part then
		part.CFrame = cf
		part.Parent = workspace.Terrain
	end

	return self
end

function Particle.Emit(self: Particle, emitCount: number?, emitCompleted: (() -> ())?): (() -> ())?
	local secondsUntilComplete = 0
	for _, v in self.Emitters do
		v:Emit(emitCount or v:GetAttribute("EmitCount") or 1)
		if v.Lifetime.Max > secondsUntilComplete then
			secondsUntilComplete = v.Lifetime.Max
		end
	end
	local function disconnect()
		self._completedConnection:Disconnect()
		self._completedConnection = nil
	end
	if self._completedConnection then
		disconnect()
	end
	if emitCompleted ~= nil then
		local startedTime = tick()
		self._completedConnection = RunService.Heartbeat:Connect(function()
			if tick() - startedTime < secondsUntilComplete then
				return
			end
			disconnect()
			emitCompleted()
		end)
		return disconnect
	end
end

function Particle.SetEnabled(self: Particle, enabled: boolean)
	for _, v in self.Emitters do
		v.Enabled = enabled
	end
end

function Particle.Destroy(self: Particle): ()
	self._trove:Destroy()
end

return Particle
