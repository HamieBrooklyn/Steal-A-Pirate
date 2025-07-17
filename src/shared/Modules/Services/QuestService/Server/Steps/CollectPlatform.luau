local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseServer = require(Services.BaseService.Server)
local Platform = require(Services.BaseService.Server.Base.Platform)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Charm = require(ReplicatedStorage.Packages.Charm)

local atom, subscribe = Charm.atom, Charm.subscribe

local scoped, peek = Fusion.scoped, Fusion.peek

local Step = {}
Step.__index = Step

type self = {
	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,
}
export type Step = typeof(setmetatable({} :: self, Step))

function Step.new(player: Player, texts: { [string]: string }, ...): Step
	local self = setmetatable({}, Step) :: Step

	self._scope = scoped(Fusion)
	self._trove = Trove.new()

	return self
end

function Step.Start(
	self: Step,
	finished: () -> (),
	player: Player,
	texts: { [string]: string },
	characterName: string
): ()
	local base = BaseServer.GetPlayerBase(player)

	local platformCons = {}
	for _, v in base.Platforms do
		self._trove:Add(self._scope:Observer(v.CharacterName):onBind(function()
			if peek(v.CharacterName) == characterName then
				platformCons[v] = self._trove:Add(v.collected:Connect(function()
					finished()
				end))
			else
				if platformCons[v] then
					platformCons[v]:Disconnect()
					platformCons[v] = nil
				end
			end
		end))
	end
end

function Step.Clean(self: Step): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Step
