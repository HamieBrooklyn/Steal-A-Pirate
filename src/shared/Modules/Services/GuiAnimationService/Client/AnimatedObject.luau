local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local scoped = Fusion.scoped

local AnimatedObject = {}
AnimatedObject.__index = AnimatedObject

type self = {
	_scope: Fusion.Scope<any>,

	Position: Fusion.Value<UDim2, any>,
	PositionSpring: Fusion.Spring<UDim2>,

	Rotation: Fusion.Value<number, any>,
	RotationSpring: Fusion.Spring<number>,

	Size: Fusion.Value<UDim2, any>,
	SizeSpring: Fusion.Spring<UDim2>,
}
export type AnimatedObject = typeof(setmetatable({} :: self, AnimatedObject))

function AnimatedObject.new(object: GuiObject): AnimatedObject
	local self = setmetatable({}, AnimatedObject) :: AnimatedObject

	local scope = scoped(Fusion)

	local position = scope:Value(object.Position)
	self.Position = position
	local positionSpring = scope:Spring(position, 25, 0.5)
	self.PositionSpring = positionSpring

	local rotation = scope:Value(object.Rotation)
	self.Rotation = rotation
	local rotationSpring = scope:Spring(rotation, 25, 0.5)
	self.RotationSpring = rotationSpring

	local size = scope:Value(object.Size)
	self.Size = size
	local sizeSpring = scope:Spring(size, 25, 0.5)
	self.SizeSpring = sizeSpring

	scope:Hydrate(object)({
		Position = positionSpring,
		Rotation = rotationSpring,
		Size = sizeSpring,
	})

	return self
end

function AnimatedObject.Destroy(self: AnimatedObject): () end

return AnimatedObject
