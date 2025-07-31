local SharedTypes = require(script.Parent.Parent.Parent.Types)

local BigMutation = {}
BigMutation.__index = BigMutation

type self = {
	data: SharedTypes.MutationData,
}
export type BigMutation = typeof(setmetatable({} :: self, BigMutation))

function BigMutation.new(char: Model, data: SharedTypes.MutationData): BigMutation
	local self = setmetatable({}, BigMutation) :: BigMutation

	task.delay(1.5, function()
		char:ScaleTo(char:GetScale() * data.Values.Scale)
	end)

	self.data = data

	return self
end

function BigMutation.Destroy(self: BigMutation): () end

return BigMutation
