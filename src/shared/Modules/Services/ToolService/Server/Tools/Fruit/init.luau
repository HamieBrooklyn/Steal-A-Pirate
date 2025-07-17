local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SomeFruit = require(script.SomeFruit)

local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local Fruit = {}
Fruit.__index = Fruit

type self = {}
export type Fruit = typeof(setmetatable({} :: self, Fruit))

function Fruit.new(player: Player, tool: Tool, remove: () -> ()): Fruit
	local self = setmetatable({}, Fruit) :: Fruit

	local fruitTypes: { [string]: SomeFruit.SomeFruit } = {}
	for _, v in script:GetChildren() do
		fruitTypes[v.Name] = require(v)
	end
	local fruitType = tool:GetAttribute("FruitType")
	if fruitType then
		local class = fruitTypes[fruitType]
		if class then
			local fruit = class.new(player, tool)
			tool.Equipped:Connect(function()
				fruit:Equipped()
			end)
			tool.Unequipped:Connect(function()
				fruit:Unequipped()
			end)
			tool.Activated:Connect(function()
				fruit:Activated(function(ignoreSound)
					if not ignoreSound then
						Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.Munch, player.Character.PrimaryPart)
							:Play()
					end
					remove()
				end)
			end)
		end
	end

	return self
end

function Fruit.Destroy(self: Fruit): () end

return Fruit
