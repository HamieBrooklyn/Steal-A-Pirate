local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TimerBoard = require(ReplicatedStorage.Shared.Modules.Components.UI.TimerBoard)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

local SomeFruit = {}
SomeFruit.__index = SomeFruit

type self = {
	player: Player,
	tool: Tool,
}
export type SomeFruit = typeof(setmetatable({} :: self, SomeFruit))

function SomeFruit.new(player: Player, tool: Tool): SomeFruit
	local self = setmetatable({}, SomeFruit) :: SomeFruit

	self._scope = Fusion.scoped(Fusion)

	self.player = player
	self.tool = tool

	return self
end

function SomeFruit.Equipped(self: SomeFruit): () end

function SomeFruit.Unequipped(self: SomeFruit): () end

function SomeFruit.Activated(self: SomeFruit): ()
	local char = self.player.Character
	if not char then
		return
	end

	local secondsLeft = self._scope:Value(0)
	local started = tick()
	local timerBoard = TimerBoard(self._scope, {
		secondsLeft = secondsLeft,
		adornee = char.PrimaryPart,
	})
	RunService.Heartbeat:Connect(function()
		secondsLeft:set(15 - (tick() - started))
		if peek(secondsLeft) <= 0 then
			timerBoard:Destroy()
		end
	end)
end

function SomeFruit.Destroy(self: SomeFruit): ()
	self._scope:doCleanup()
end

return SomeFruit
