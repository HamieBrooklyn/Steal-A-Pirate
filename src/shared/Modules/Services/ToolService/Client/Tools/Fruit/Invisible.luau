local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)
local Trove = require(ReplicatedStorage.Packages.Trove)
local TimerBoard = require(ReplicatedStorage.Shared.Modules.Components.UI.TimerBoard)

local Children = Fusion.Children
local scoped, peek = Fusion.scoped, Fusion.peek

local InvisibleFruit = {}
InvisibleFruit.__index = InvisibleFruit

type self = {
	player: Player,
	tool: Tool,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,
}
export type InvisibleFruit = typeof(setmetatable({} :: self, InvisibleFruit))

function InvisibleFruit.new(player: Player, tool: Tool): InvisibleFruit
	local self = setmetatable({}, InvisibleFruit) :: InvisibleFruit

	self._scope = scoped(Fusion)
	self._trove = Trove.new()

	self.player = player
	self.tool = tool

	return self
end

function InvisibleFruit.Equipped(self: InvisibleFruit): () end

function InvisibleFruit.Unequipped(self: InvisibleFruit): () end

function InvisibleFruit.Activated(self: InvisibleFruit): ()
	local char = self.player.Character
	if not char or char:GetAttribute("Invisible") then
		return
	end
	local root = char.PrimaryPart
	if not root then
		return
	end

	local secondsLeft = self._scope:Value(0)
	local started = tick()
	local timerBoard = TimerBoard(self._scope, {
		secondsLeft = secondsLeft,
		adornee = root,
	})
	RunService.Heartbeat:Connect(function()
		secondsLeft:set(15 - (tick() - started))
		if peek(secondsLeft) <= 0 then
			timerBoard:Destroy()
		end
	end)
end

function InvisibleFruit.Destroy(self: InvisibleFruit): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return InvisibleFruit
