local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SoundEffects = ReplicatedStorage.Assets.Sounds.SoundEffects

local BombFruitModel = ReplicatedStorage.Assets.Models.Fruits["Bomb Bomb Fruit"]

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)
local Particle = require(ReplicatedStorage.Shared.Modules.Classes.Particle)

local BombFruit = {}
BombFruit.__index = BombFruit

type self = {
	player: Player,
	tool: Tool,
}
export type BombFruit = typeof(setmetatable({} :: self, BombFruit))

function BombFruit.new(player: Player, tool: Tool): BombFruit
	local self = setmetatable({}, BombFruit) :: BombFruit

	self.player = player
	self.tool = tool

	return self
end

function BombFruit.Equipped(self: BombFruit): () end

function BombFruit.Unequipped(self: BombFruit): () end

function BombFruit.Activated(self: BombFruit, used: () -> ()): ()
	local char = self.player.Character
	if not char then
		return
	end
	local root = char.PrimaryPart
	if not root then
		return
	end

	local model: Model = BombFruitModel:Clone()
	model:PivotTo(self.tool:FindFirstChild("Handle"):GetPivot())
	model.Parent = workspace.Terrain

	local delta = root:GetPivot().LookVector

	local bv = Instance.new("BodyVelocity")
	bv.maxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.velocity = (delta.Unit * 50) + Vector3.yAxis * 50
	bv.Parent = model.PrimaryPart
	Debris:AddItem(bv, 0.05)

	local particle = Particle.new(ReplicatedStorage.Assets.VFX.Particles.Explosion, Vector3.zero)

	self:Destroy()
	Sound.new(SoundEffects.Throw, root):Play()

	used(true)

	task.delay(2, function()
		local p = Instance.new("Part")
		p.Anchored = true
		p.Transparency = 1
		p:PivotTo(model:GetPivot())
		p.Parent = workspace.Terrain
		Debris:AddItem(p, 5)
		Sound.new(SoundEffects.Explode, p):Play()

		particle.part:PivotTo(p:GetPivot())
		particle:Emit(nil, function()
			particle:Destroy()
		end)

		model:Destroy()

		for _, v: Player in Players:GetPlayers() do
			local otherChar = v.Character
			if otherChar == self.player.Character then
				continue
			end
			if otherChar then
				local otherRoot = otherChar.PrimaryPart
				local otherHum = otherChar:FindFirstChildOfClass("Humanoid")
				if otherRoot and (otherRoot:GetPivot().Position - model:GetPivot().Position).Magnitude < 20 then
					local delta2 = root:GetPivot().Position - model:GetPivot().Position

					local bv2 = Instance.new("BodyVelocity")
					bv2.maxForce = Vector3.new(1e9, 1e9, 1e9)
					bv2.velocity = (delta2.Unit * 100) + Vector3.yAxis * 100
					bv2.Parent = otherRoot
					Debris:AddItem(bv2, 0.05)

					if otherHum then
						otherHum.Sit = true
					end
				end
			end
		end
	end)
end

function BombFruit.Destroy(self: BombFruit): ()
	self.tool:Destroy()
end

return BombFruit
