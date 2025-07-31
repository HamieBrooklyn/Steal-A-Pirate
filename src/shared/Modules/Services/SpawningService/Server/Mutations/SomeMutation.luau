local SharedTypes = require(script.Parent.Parent.Parent.Types)

local SomeMutation = {}
SomeMutation.__index = SomeMutation

type self = {
	data: SharedTypes.MutationData,
}
export type SomeMutation = typeof(setmetatable({} :: self, SomeMutation))

function SomeMutation.new(char: Model, data: SharedTypes.MutationData): SomeMutation
	local self = setmetatable({}, SomeMutation) :: SomeMutation

	self.data = data

	return self
end

function SomeMutation.Destroy(self: SomeMutation): () end

return SomeMutation
