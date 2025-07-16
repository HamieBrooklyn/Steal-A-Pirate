local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SurfaceBoard = require(script.SurfaceBoard)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Value = Fusion.Value
local scoped, peek, doCleanup = Fusion.scoped, Fusion.peek, Fusion.doCleanup

local GlobalLeaderboard = {}
GlobalLeaderboard.__index = GlobalLeaderboard

type self = {
	id: string,

	scope: Fusion.Scope<{
		SurfaceBoard: typeof(SurfaceBoard),
	}>,
	trove: Trove.Trove,

	formatString: Fusion.Value<string, any>,
	abbreviate: Fusion.Value<boolean, any>,

	listedRanks: Fusion.Value<{ key: string, value: number }, any>,
}
export type GlobalLeaderboard = typeof(setmetatable({} :: self, GlobalLeaderboard))

function GlobalLeaderboard.new(instance: Model): GlobalLeaderboard
	local self = setmetatable({}, GlobalLeaderboard) :: GlobalLeaderboard

	self.id = instance:GetAttribute("GlobalLeaderboardId")

	self.scope = scoped(Fusion, {
		SurfaceBoard = SurfaceBoard,
	})
	self.trove = Trove.new()

	self.stringFormat = Value(self.scope, instance:GetAttribute("StringFormat") or "")
	self.abbreviate = Value(self.scope, instance:GetAttribute("Abbreviate") == true)

	self.listedRanks = Value(self.scope, {})
	-- Observer(self.scope, self.listedRanks):onBind(function()
	-- 	print(peek(self.listedRanks))
	-- end)

	self.trove:Add(Streamable.primary(instance):Observe(function(root: BasePart, rootTrove: Trove.Trove)
		rootTrove:Add(self.scope:SurfaceBoard({
			listedItems = self.listedRanks,
			stringFormat = peek(self.stringFormat),
			abbreviate = peek(self.abbreviate),
		})).Parent =
			root
	end))

	return self
end

function GlobalLeaderboard.Destroy(self: GlobalLeaderboard): ()
	doCleanup(self.scope)
	self.trove:Destroy()
end

return GlobalLeaderboard
