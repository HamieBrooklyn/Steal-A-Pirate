local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Children = Fusion.New, Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function CloseButton(
	scope: Fusion.Scope<any>,
	props: {
		anchorPoint: UsedAs<UDim2>,
		position: UsedAs<UDim2>,
		size: UsedAs<UDim2>,

		target: UsedAs<Instance>,

		layoutOrder: UsedAs<number?>,
	}
): Fusion.Child
	local button = New(scope, "ImageButton")({
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = props.size,

		BackgroundTransparency = 1,

		Image = "rbxassetid://80396875641393",

		LayoutOrder = props.layoutOrder,

		[Children] = {
			New(scope, "UIAspectRatioConstraint")({}),
			New(scope, "ObjectValue")({
				Name = "Close",
				Value = props.target,
			}),
		},
	})
	button:AddTag("CloseButton")
	button:AddTag("AnimatedButton")

	return button
end

return CloseButton
