local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Children = Fusion.New, Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

export type IconProps = {
	Image: UsedAs<string>,
	Rotation: UsedAs<number>,

	Position: UsedAs<UDim2>,
	Size: UsedAs<UDim2>,
}

local function Icon(scope: Fusion.Scope<any>, props: IconProps): Fusion.Child
	return New(scope, "ImageLabel")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = props.Position,
		Size = props.Size,
		Rotation = props.Rotation,

		Image = props.Image,

		BackgroundTransparency = 1,

		[Children] = New(scope, "UIAspectRatioConstraint")({}),
	})
end

return Icon
