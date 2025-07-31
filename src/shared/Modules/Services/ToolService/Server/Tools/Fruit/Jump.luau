local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)
local TimerBoard = require(ReplicatedStorage.Shared.Modules.Components.UI.TimerBoard)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local peek = Fusion.peek

local JumpFruit = {}
JumpFruit.__index = JumpFruit

type self = {
	player: Player,
	tool: Tool,

	_trove: Trove.Trove,
}
export type JumpFruit = typeof(setmetatable({} :: self, JumpFruit))

function JumpFruit.new(player: Player, tool: Tool): JumpFruit
	local self = setmetatable({}, JumpFruit) :: JumpFruit

	self._trove = Trove.new()

	self.player = player
	self.tool = tool

	return self
end

function JumpFruit.Equipped(self: JumpFruit): () end

function JumpFruit.Unequipped(self: JumpFruit): () end

function JumpFruit.Activated(self: JumpFruit, used: () -> ()): ()
	local char = self.player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	local animatedHighlight: AnimatedHighlight.AnimatedHighlight = self._trove:Add(AnimatedHighlight.new({
		FillColor = Color3.fromRGB(65, 75, 255),
		OutlineColor = Color3.fromRGB(70, 79, 255),
	}, char))
	animatedHighlight:Pulse()

	hum.JumpHeight = StarterPlayer.CharacterJumpHeight + 15
	used()

	task.delay(15, function()
		if hum then
			hum.JumpHeight = StarterPlayer.CharacterJumpHeight
		end
	end)
end

function JumpFruit.Destroy(self: JumpFruit): ()
	self._trove:Destroy()
end

return JumpFruit
