local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local TextButton = require(ReplicatedStorage.Shared.Modules.Components.UI.TextButton)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

type UsedAs<T> = Fusion.UsedAs<T>

export type PaySpinButtonProps = {
	text: UsedAs<string>,
	getText: UsedAs<string>,

	native: UsedAs<{ [string]: any }>,
	children: UsedAs<{ Fusion.Child }>,

	clicked: () -> (),
}

local function PaySpinButton(scope: Fusion.Scope<any>, props: PaySpinButtonProps): Fusion.Child
	return TextButton(scope, {
		text = props.text,

		backgroundColor = Color3.fromHex("#0fffe7"),

		clicked = props.clicked,

		native = props.native,
		children = {
			Info = Text(scope, {
				anchorPoint = Vector2.new(0.5, 0),
				position = UDim2.fromScale(0.5, 0.8),
				size = UDim2.fromScale(0.5, 0.5),

				text = props.getText,
			}),
		},
	})
end

return PaySpinButton
