local SomeFruit = {}
SomeFruit.__index = SomeFruit

type self = {
	player: Player,
	tool: Tool,
}
export type SomeFruit = typeof(setmetatable({} :: self, SomeFruit))

function SomeFruit.new(player: Player, tool: Tool): SomeFruit
	local self = setmetatable({}, SomeFruit) :: SomeFruit

	self.player = player
	self.tool = tool

	return self
end

function SomeFruit.Equipped(self: SomeFruit): () end

function SomeFruit.Unequipped(self: SomeFruit): () end

function SomeFruit.Activated(self: SomeFruit): () end

function SomeFruit.Destroy(self: SomeFruit): () end

return SomeFruit
