local None = {}
None.__index = None

type self = {}
export type None = typeof(setmetatable({} :: self, None))

function None.new(player: Player, tool: Tool, remove: () -> ()): None
	local self = setmetatable({}, None) :: None

	return self
end

function None.Destroy(self: None): () end

return None
