local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Children = Fusion.New, Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function SquareIcon(
	scope: Fusion.Scope<any>,
	props: {
		anchorPoint: UsedAs<Vector2?>,
		position: UsedAs<UDim2?>,
		size: UsedAs<UDim2?>,

		image: UsedAs<string>,

		layoutOrder: UsedAs<number?>,
	}
)
	return New(scope, "ImageLabel")({
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = props.size,

		Image = props.image,

		BackgroundTransparency = 1,

		LayoutOrder = props.layoutOrder,

		[Children] = New(scope, "UIAspectRatioConstraint")({}),
	})
end

return SquareIcon
