local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)

local fireRayGunAttempt = Net:RemoteEvent("FireRayGunAttempt")

local mouse = Players.LocalPlayer:GetMouse()

local RayGun = {}
RayGun.__index = RayGun

type self = {
	_trove: Trove.Trove,
}

export type RayGun = typeof(setmetatable({} :: self, RayGun)) & RayGun

function RayGun.new(tool: Tool): RayGun
	local self = setmetatable({} :: RayGun, RayGun)

	self._trove = Trove.new()

	tool.Activated:Connect(function()
		fireRayGunAttempt:FireServer(tool, mouse.Hit.Position)
	end)

	return self
end

function RayGun.Destroy(self: RayGun): ()
	self._trove:Destroy()
end

return RayGun
