local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local joinTables = require(ReplicatedStorage.Shared.Modules.Utilities.joinTables)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local InteractButton = require(ReplicatedStorage.Shared.Modules.Components.UI.InteractButton)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

export type IconTextButtonProps = {
	native: UsedAs<{ [string]: any }>,

	text: UsedAs<string>,
	icon: UsedAs<string>,

	backgroundColor: UsedAs<Color3>,
	textColor: UsedAs<Color3>,
	outlineColor: UsedAs<Color3>,

	clicked: () -> (),
}

local function TextButton(scope: Fusion.Scope<any>, props: TextButtonProps): Fusion.Child
	return scope:New("Frame")(joinTables({
		BackgroundTransparency = 1,

		[Children] = joinTables({
			Frame = scope:New("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = props.backgroundColor,
				BorderColor3 = props.outlineColor,
				BorderSizePixel = 2,
			}),
			Text = Text(scope, {
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(1, 0.5),

				text = props.text,
			}),
			Interact = InteractButton(scope, {
				size = UDim2.fromScale(1, 1),
				clicked = props.clicked,
			}),
		}, props.children),
	}, props.native))
end

return TextButton
