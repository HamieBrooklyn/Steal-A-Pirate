local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)
local Trove = require(ReplicatedStorage.Packages.Trove)

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
	if not char then
		return
	end
	local root = char.PrimaryPart
	if not root then
		return
	end

	local secondsLeft = self._scope:Value(0)
	self._scope:New("BillboardGui")({
		Name = "InvisibleTimer",
		Size = UDim2.fromScale(5, 2),
		StudsOffset = Vector3.new(0, 5, 0),
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
		Adornee = root,
		[Children] = Text(self._scope, {
			size = UDim2.fromScale(1, 1),
			text = self._scope:Computed(function(use)
				return formatTime(use(secondsLeft), {
					mode = "text",
					showDays = false,
					showHours = false,
					showMinutes = false,
					showSeconds = true,
					showMilliseconds = true,
				})
			end),
		}),
	})
	local started = tick()
	self._trove:Add(RunService.Heartbeat:Connect(function()
		secondsLeft:set(15 - (tick() - started))
		if peek(secondsLeft) <= 0 then
			self:Destroy()
		end
	end))
end

function InvisibleFruit.Destroy(self: InvisibleFruit): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return InvisibleFruit
