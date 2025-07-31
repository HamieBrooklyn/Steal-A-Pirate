local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BananaModel = ReplicatedStorage.Assets.Models.Banana

local BananaSounds = ReplicatedStorage.Assets.Sounds.SoundEffects.Banana

local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local SharedData = require(script.Parent.Parent.Parent.Parent.Data)

local Trove = require(ReplicatedStorage.Packages.Trove)

local BearTrap = {}
BearTrap.__index = BearTrap

type self = {
	trove: Trove.Trove,
	model: Model,
	toucher: Toucher.Toucher,
}
export type BearTrap = typeof(setmetatable({} :: self, BearTrap))

function BearTrap.new(placer: Player, position: Vector3, removed: () -> ()): BearTrap
	local self = setmetatable({}, BearTrap) :: BearTrap

	self.trove = Trove.new()

	self.model = self.trove:Add(BananaModel:Clone())
	self.model:PivotTo(
		CFrame.new(position) * CFrame.new(0, self.model:GetExtentsSize().Y / 2, 0) * CFrame.Angles(math.rad(90), 0, 0)
	)
	self.model.Parent = workspace.Terrain

	Sound.new(BananaSounds.Place, self.model.PrimaryPart):Play()

	self.trove:Add(removed)
	task.delay(SharedData.FloorItemsRemoveDuration, function()
		self:Destroy()
	end)

	self.toucher = self.trove:Add(Toucher.new(self.model))
	self.toucher.PlayerTouched:Connect(function(player: Player)
		if player == placer then
			return
		end
		local char = player.Character
		if char then
			local root = char.PrimaryPart
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Sit = true
			end

			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.Transparency = 1
			p:PivotTo(self.model:GetPivot())
			p.Parent = workspace.Terrain
			Debris:AddItem(p, 2)

			Sound.new(BananaSounds.Slip, p):Play()

			local delta = self.model:GetPivot().Position - root.Position

			local bv = Instance.new("BodyVelocity")
			bv.maxForce = Vector3.new(0, 1e9, 0)
			bv.velocity = (delta.Unit * 40) + Vector3.yAxis * 30
			bv.Parent = root
			Debris:AddItem(bv, 0.05)

			self.model:Destroy()
			self:Destroy()
			removed()
		end
	end)
	local con
	con = placer.AncestryChanged:Connect(function(child, parent)
		if parent == nil then
			self:Destroy()
		end
	end)

	return self
end

function BearTrap.Destroy(self: BearTrap): ()
	self.trove:Destroy()
end

return BearTrap
