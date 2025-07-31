local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children, OnEvent = Fusion.Children, Fusion.OnEvent

type UsedAs<T> = Fusion.UsedAs<T>

local function InteractButton(
	scope: Fusion.Scope<any>,
	props: {
		anchorPoint: UsedAs<UDim2>,
		position: UsedAs<UDim2>,
		size: UsedAs<UDim2>,

		clicked: (() -> ())?,

		interactable: UsedAs<boolean>,
		animated: UsedAs<Instance>,
	}
): Fusion.Child
	local button = scope:New("ImageButton")({
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = props.size,

		Interactable = props.interactable,

		Image = "",

		LayoutOrder = 10,

		[OnEvent("MouseButton1Click")] = props.clicked,

		BackgroundTransparency = 1,

		[Children] = {
			scope:New("ObjectValue")({
				Name = "Animate",
				Value = props.animated,
			}),
		},
	})
	if props.animated then
		button:AddTag("AnimatedButton")
	end

	return button
end

return InteractButton
