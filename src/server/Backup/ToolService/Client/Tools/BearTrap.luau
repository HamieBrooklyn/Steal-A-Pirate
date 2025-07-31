local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Net = require(ReplicatedStorage.Packages.Net)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local placeFloorItem = Net:RemoteEvent("PlaceFloorItem")

local BearTrap = {}
BearTrap.__index = BearTrap

type self = {
	mouse: Mouse?,
}
export type BearTrap = typeof(setmetatable({} :: self, BearTrap))

function BearTrap.new(tool: Tool): BearTrap
	local self = setmetatable({}, BearTrap) :: BearTrap

	local params = RaycastParams.new()
	tool.Activated:Connect(function()
		local char = player.Character
		params.FilterDescendantsInstances = { char }
		if mouse and char then
			local origin = char:GetPivot().Position
			local dir = mouse.Hit.Position - origin
			local result: RaycastResult? = workspace:Raycast(origin, dir * 15, params)
			if result and result.Position then
				if (origin - result.Position).Magnitude > 15 then
					return
				end
				placeFloorItem:FireServer(tool, result.Position)
			end
		end
	end)

	return self
end

function BearTrap.Destroy(self: BearTrap): () end

return BearTrap
