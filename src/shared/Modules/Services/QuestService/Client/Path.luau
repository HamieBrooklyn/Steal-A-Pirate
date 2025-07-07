local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PathfinderBeamTemp = ReplicatedStorage.Assets.VFX.Pathfinder

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local scoped = Fusion.scoped

local Path = {}
Path.__index = Path

type self = {
	scope: Fusion.Scope<any>,

	from: Fusion.Value<BasePart, any>,
	to: Fusion.Value<BasePart, any>,

	attachment0: Attachment,
	attachment1: Attachment,

	pathfinder: Beam,
}
export type Path = typeof(setmetatable({} :: self, Path))

function Path.new(scope: Fusion.Scope<any>?): Path
	local self = setmetatable({}, Path) :: Path

	self.scope = scope and scope:innerScope() or scoped(Fusion)
	self.from = scope:Value(nil)
	self.to = scope:Value(nil)

	for i = 0, 1 do
		self["attachment" .. tostring(i)] = self.scope:New("Attachment")({
			Parent = i == 1 and self.from or self.to,
		})
	end

	self.pathfinder = self.scope:Hydrate(PathfinderBeamTemp:Clone())({
		Attachment0 = self.attachment0,
		Attachment1 = self.attachment1,
		Parent = self.from,
	})

	return self
end

function Path.Destroy(self: Path): ()
	self.scope:doCleanup()
end

return Path
