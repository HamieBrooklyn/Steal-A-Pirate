local RunService = game:GetService("RunService")

local FloatingItem = {}
FloatingItem.__index = FloatingItem

type self = {
	root: BasePart,

	speed: number,
}
export type FloatingItem = typeof(setmetatable({} :: self, FloatingItem))

function FloatingItem.new(item: BasePart | Model): FloatingItem
	local self = setmetatable({}, FloatingItem) :: FloatingItem

	self.mainPart = item:IsA("BasePart") and item or item:IsA("Model") and item.PrimaryPart
	self.speed = item:GetAttribute("Speed") or 1
	self.maxHeight = item:GetAttribute("MaxHeight") or 1

	local baseCFrame = self.mainPart.CFrame

	local time = 0

	self.runCon = RunService.Heartbeat:Connect(function(dt)
		time += dt * self.speed

		local bob = math.sin(time * 2) * self.maxHeight
		local spin = CFrame.Angles(0, time * 0.5, 0)
		local targetCFrame = CFrame.new(baseCFrame.Position + Vector3.new(0, bob, 0)) * spin

		item:PivotTo(self.mainPart.CFrame:Lerp(targetCFrame, 0.1))
	end)

	return self
end

function FloatingItem.Destroy(self: FloatingItem): ()
	self.runCon:Disconnect()
end

return FloatingItem
