local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PathBeam = ReplicatedStorage.Assets.VFX.Pathfinder

local Trove = require(ReplicatedStorage.Packages.Trove)
local Charm = require(ReplicatedStorage.Packages.Charm)

local atom, subscribe = Charm.atom, Charm.subscribe

local Path = {}
Path.__index = Path

type self = {
	fromAtom: Charm.Atom<Instance?>,
	toAtom: Charm.Atom<Instance?>,

	attachment0: Attachment,
	attachment1: Attachment,

	_trove: Trove.Trove,
}
export type Path = typeof(setmetatable({} :: self, Path))

function Path.new(from: BasePart, to: BasePart): Path
	local self = setmetatable({}, Path) :: Path

	self.fromAtom = atom(from)
	self.toAtom = atom(to)

	self._trove = Trove.new()

	for i = 0, 1 do
		local newAttach = Instance.new("Attachment")
		newAttach.Parent = if i == 0 then from else to
		newAttach.Name = "Pathfind_" .. if i == 0 then "From" else "To"
		subscribe(self[if i == 0 then "fromAtom" else "toAtom"], function(state)
			newAttach.Parent = state
		end)
		self[`attachment{i}`] = self._trove:Add(newAttach)
	end

	local path = self._trove:Add(PathBeam:Clone()) :: Beam
	path.Attachment0 = self.attachment0
	path.Attachment1 = self.attachment1
	path.Parent = workspace.Terrain

	return self
end

function Path.Destroy(self: Path): ()
	self._trove:Destroy()
end

return Path
