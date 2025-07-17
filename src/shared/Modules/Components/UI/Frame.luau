local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function Frame(
	scope: Fusion.Scope<any>,
	props: {
		anchorPoint: UsedAs<UDim2>,
		position: UsedAs<UDim2>,
		size: UsedAs<UDim2>,

		bgColor: UsedAs<Color3>?,

		cornerRadius: UsedAs<UDim>?,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,

		children: { Fusion.Child },
	}
): Fusion.Child
	return scope:New("Frame")({
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = props.size,

		BackgroundTransparency = 0.75,
		BackgroundColor3 = props.bgColor or Color3.new(),

		[Children] = {
			scope:New("UIStroke")({
				Thickness = props.strokeThickness,
				Color = props.strokeColor,
			}),
			scope:New("UICorner")({
				CornerRadius = props.cornerRadius or UDim.new(0.1, 0),
			}),
			props.children,
		},
	})
end

return Frame
