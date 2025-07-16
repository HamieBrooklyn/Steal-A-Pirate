local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrapModel = ReplicatedStorage.Assets.Models.BearTrap

local BearTrapSounds = ReplicatedStorage.Assets.Sounds.SoundEffects.BearTrap

local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local Trove = require(ReplicatedStorage.Packages.Trove)

local BearTrap = {}
BearTrap.__index = BearTrap

type self = {
	trove: Trove.Trove,
	model: Model,
	toucher: Toucher.Toucher,
}
export type BearTrap = typeof(setmetatable({} :: self, BearTrap))

function BearTrap.new(placer: Player, position: Vector3): BearTrap
	local self = setmetatable({}, BearTrap) :: BearTrap

	self.trove = Trove.new()

	self.model = self.trove:Add(TrapModel:Clone())
	self.model:PivotTo(CFrame.new(position) * CFrame.new(0, self.model:GetExtentsSize().Y / 2, 0))
	self.model.Parent = workspace.Terrain

	Sound.new(BearTrapSounds.Lay, self.model.PrimaryPart):Play()

	self.toucher = self.trove:Add(Toucher.new(self.model))
	self.toucher.PlayerTouched:Connect(function(player: Player)
		if player == placer then
			return
		end
		local char = player.Character
		if char then
			local root = char.PrimaryPart
			for _, v: BasePart? in self.model:GetChildren() do
				if v.Name:find("Half") then
					v:PivotTo(v:GetPivot() * CFrame.Angles(math.rad(-70), 0, 0))
				end
			end
			Sound.new(BearTrapSounds.Clamp, self.model.PrimaryPart):Play()
			if root then
				root.Anchored = true
				task.delay(5, function()
					if root then
						root.Anchored = false
					end
					self:Destroy()
				end)
			end
		end
	end)
	placer.AncestryChanged:Connect(function(child, parent)
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
