local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function StepText(
	scope: Fusion.Scope<any>,
	props: {
		text: UsedAs<string>,
		shown: UsedAs<boolean>,
	}
): Fusion.Child
	return Text(scope, {
		anchorPoint = Vector2.new(0.5, 1),
		position = scope:Spring(
			scope:Computed(function(use)
				return use(props.shown) and UDim2.fromScale(0.5, 0.23) or UDim2.fromScale(0.5, 0.1)
			end),
			15,
			0.7
		),
		size = UDim2.fromScale(0.6, 0.1),

		text = props.text,
		textColor = scope:Tween(
			scope:Computed(function(use)
				return use(props.shown) and Color3.new(1, 1, 1) or Color3.new(0, 1, 0)
			end),
			TweenInfo.new(0.2)
		),
		transparency = scope:Tween(
			scope:Computed(function(use)
				return use(props.shown) and 0 or 1
			end),
			TweenInfo.new(0.1)
		),
	})
end

return StepText
