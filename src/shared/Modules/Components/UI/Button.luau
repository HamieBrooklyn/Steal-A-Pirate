local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local InteractButton = require(ReplicatedStorage.Shared.Modules.Components.UI.InteractButton)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function Button(
	scope: Fusion.Scope<any>,
	props: {
		text: UsedAs<string>,

		callback: () -> (),

		Position: UsedAs<UDim2>,
		BackgroundColor: UsedAs<Color3>,
	}
)
	return scope:New("Frame")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = props.Position,
		Size = UDim2.fromScale(0.4, 0.3),

		BackgroundTransparency = 1,

		[Children] = {
			scope:New("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = props.BackgroundColor,
				[Children] = scope:New("UIStroke")({ Thickness = 2 }),
			}),
			Text(scope, {
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(1, 0.5),

				text = props.text,
			}),
			InteractButton(scope, {
				size = UDim2.fromScale(1, 1),
				clicked = props.callback,
			}),
		},
	})
end

return Button
