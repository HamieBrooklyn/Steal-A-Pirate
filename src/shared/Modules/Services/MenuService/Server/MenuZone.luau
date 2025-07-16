local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)

local scoped = Fusion.scoped

local MenuZone = {}
MenuZone.__index = MenuZone

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	toucher: Toucher.Toucher,

	playerEntered: Signal.Signal,
	playerLeft: Signal.Signal,
}
export type MenuZone = typeof(setmetatable({} :: self, MenuZone))

function MenuZone.new(zonePart: BasePart): MenuZone
	local self = setmetatable({}, MenuZone) :: MenuZone

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.playerEntered = self.trove:Add(Signal.new()) :: Signal.Signal
	self.playerLeft = self.trove:Add(Signal.new()) :: Signal.Signal

	self.toucher = self.trove:Add(Toucher.new(zonePart)) :: Toucher.Toucher
	self.trove:Add(self.toucher.PlayerTouched:Connect(function(player: Player)
		self.playerEntered:Fire(player, zonePart.Name)
	end))
	self.trove:Add(self.toucher.PlayerTouchEnded:Connect(function(player: Player)
		self.playerLeft:Fire(player, zonePart.Name)
	end))

	return self
end

function MenuZone.Destroy(self: MenuZone): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return MenuZone
