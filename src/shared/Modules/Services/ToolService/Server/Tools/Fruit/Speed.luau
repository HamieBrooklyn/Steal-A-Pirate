local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)
local TimerBoard = require(ReplicatedStorage.Shared.Modules.Components.UI.TimerBoard)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local peek = Fusion.peek

local SomeFruit = {}
SomeFruit.__index = SomeFruit

type self = {
	player: Player,
	tool: Tool,

	_trove: Trove.Trove,
}
export type SomeFruit = typeof(setmetatable({} :: self, SomeFruit))

function SomeFruit.new(player: Player, tool: Tool): SomeFruit
	local self = setmetatable({}, SomeFruit) :: SomeFruit

	self._trove = Trove.new()

	self.player = player
	self.tool = tool

	return self
end

function SomeFruit.Equipped(self: SomeFruit): () end

function SomeFruit.Unequipped(self: SomeFruit): () end

function SomeFruit.Activated(self: SomeFruit, used: () -> ()): ()
	local char = self.player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	local animatedHighlight: AnimatedHighlight.AnimatedHighlight = self._trove:Add(AnimatedHighlight.new({
		FillColor = Color3.fromRGB(252, 255, 65),
		OutlineColor = Color3.fromRGB(255, 175, 70),
	}, char))
	animatedHighlight:Pulse()

	hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed + 15
	used()

	task.delay(15, function()
		if hum then
			hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		end
	end)
end

function SomeFruit.Destroy(self: SomeFruit): () end

return SomeFruit
