local SomeTool = {}
SomeTool.__index = SomeTool

type self = {}
export type SomeTool = typeof(setmetatable({} :: self, SomeTool))

function SomeTool.new(player: Player, tool: Tool, remove: () -> ()): SomeTool
	local self = setmetatable({}, SomeTool) :: SomeTool
	return self
end

function SomeTool.Destroy(self: SomeTool): () end

return SomeTool
