local SharedSpawningData = require(script.Parent.Parent.Data)

local mutations = {}
for _, v in script.Parent.Mutations:GetChildren() do
	mutations[v.Name] = require(v)
end

local Mutated = {}
Mutated.__index = Mutated

type self = {}
export type Mutated = typeof(setmetatable({} :: self, Mutated))

function Mutated.new(char: Model): Mutated
	local self = setmetatable({}, Mutated) :: Mutated

	local mutationString: string = char:GetAttribute("Mutations")
	for _, v in mutationString:split(",") do
		local mutData = SharedSpawningData.Mutations[v]
		mutations[mutData.Class].new(char, mutData)
	end

	return self
end

function Mutated.Destroy(self: Mutated): () end

return Mutated
