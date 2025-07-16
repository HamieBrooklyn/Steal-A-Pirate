local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Computed, Children = Fusion.New, Fusion.Computed, Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function Label(
	scope: Fusion.Scope<any>,
	props: {
		anchorPoint: UsedAs<Vector2?>,
		position: UsedAs<UDim2?>,
		size: UsedAs<UDim2?>,

		text: UsedAs<string>,
		textColor: UsedAs<Color3?>,
		fontFace: UsedAs<Font?>,
		textXAlignment: UsedAs<Enum.TextXAlignment?>,

		layoutOrder: UsedAs<number?>,
	}
)
	return New(scope, "TextLabel")({
		AnchorPoint = props.anchorPoint,
		Position = props.position,
		Size = props.size,

		Text = props.text,
		TextColor3 = Computed(scope, function(use)
			return use(props.textColor) or Color3.new(1, 1, 1)
		end),
		TextScaled = true,
		FontFace = Computed(scope, function(use)
			return use(props.font)
				or Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		end),
		TextXAlignment = props.textXAlignment,

		BackgroundTransparency = 1,

		LayoutOrder = props.layoutOrder,

		[Children] = New(scope, "UIStroke")({ Thickness = 2 }),
	})
end

return Label
