local InvisibleFruit = {}
InvisibleFruit.__index = InvisibleFruit

type self = {
	player: Player,
	tool: Tool,
}
export type InvisibleFruit = typeof(setmetatable({} :: self, InvisibleFruit))

function InvisibleFruit.new(player: Player, tool: Tool): InvisibleFruit
	local self = setmetatable({}, InvisibleFruit) :: InvisibleFruit

	self.player = player
	self.tool = tool

	return self
end

function InvisibleFruit.Equipped(self: InvisibleFruit): () end

function InvisibleFruit.Unequipped(self: InvisibleFruit): () end

function InvisibleFruit.Activated(self: InvisibleFruit, used: () -> ()): ()
	local char = self.player.Character
	if not char or char:GetAttribute("Invisible") then
		return
	end
	char:SetAttribute("Invisible", true)
	used()

	local parts: { [Instance]: number } = {}
	for _, p in char:GetDescendants() do
		if p:IsA("BasePart") or p:IsA("Decal") then
			parts[p] = p.Transparency
			p.Transparency = 0.97
		end
	end
	char:FindFirstChildOfClass("Humanoid").NameDisplayDistance = Enum.HumanoidDisplayDistanceType.None

	task.delay(15, function()
		if char then
			for i, v in parts do
				i.Transparency = v
			end
			char:SetAttribute("Invisible", false)
			char:FindFirstChildOfClass("Humanoid").NameDisplayDistance = Enum.HumanoidDisplayDistanceType.Viewer
		end
	end)
end

function InvisibleFruit.Destroy(self: InvisibleFruit): () end

return InvisibleFruit
