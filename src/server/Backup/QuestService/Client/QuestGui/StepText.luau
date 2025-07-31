local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function StepText(
	scope: Fusion.Scope<any>,
	props: {
		text: UsedAs<string>,
	}
): Fusion.Child
	return Text(scope, {
		anchorPoint = Vector2.new(0.5, 1),
		position = UDim2.fromScale(0.5, 0.3),
		size = UDim2.fromScale(0.6, 0.15),

		text = props.text,
	})
end

return StepText
