-- ModuleScript: VolumeWatcher.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local VolumeWatcher = {}
VolumeWatcher.__index = VolumeWatcher

function VolumeWatcher.new(regionPart, pollRate)
	local self = setmetatable({}, VolumeWatcher)
	self.Part = regionPart
	self.PollRate = pollRate or 1 / 15
	self._acc = 0
	self._inside = {}
	self.PlayerEntered = Instance.new("BindableEvent")
	self.PlayerLeft = Instance.new("BindableEvent")
	self._params = OverlapParams.new()
	self._params.FilterType = Enum.RaycastFilterType.Include
	self._conn = RunService.Heartbeat:Connect(function(dt)
		self:_step(dt)
	end)
	return self
end

function VolumeWatcher:_step(dt)
	self._acc += dt
	if self._acc < self.PollRate then
		return
	end
	self._acc = 0

	local parts = workspace:GetPartBoundsInBox(self.Part.CFrame, self.Part.Size, self._params)
	local seen = {}

	for _, p in ipairs(parts) do
		local character = p:FindFirstAncestorWhichIsA("Model")
		if character then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				seen[player] = true
				if not self._inside[player] then
					self._inside[player] = true
					self.PlayerEntered:Fire(player, character)
				end
			end
		end
	end

	for player in pairs(self._inside) do
		if not seen[player] then
			self._inside[player] = nil
			self.PlayerLeft:Fire(player)
		end
	end
end

function VolumeWatcher:SetWhitelist(instances)
	self._params.FilterDescendantsInstances = instances
end

function VolumeWatcher:Destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	self.PlayerEntered:Destroy()
	self.PlayerLeft:Destroy()
end

return VolumeWatcher
