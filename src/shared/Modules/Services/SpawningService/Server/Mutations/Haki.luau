local SharedTypes = require(script.Parent.Parent.Parent.Types)

local HakiMutation = {}
HakiMutation.__index = HakiMutation

type self = {
	data: SharedTypes.MutationData,
}
export type HakiMutation = typeof(setmetatable({} :: self, HakiMutation))

function HakiMutation.new(char: Model, data: SharedTypes.MutationData): HakiMutation
	local self = setmetatable({}, HakiMutation) :: HakiMutation

	self.data = data

	for _, v in data.Values.VFX:GetChildren() do
		v:Clone().Parent = char.PrimaryPart
	end

	return self
end

function HakiMutation.Destroy(self: HakiMutation): () end

return HakiMutation
