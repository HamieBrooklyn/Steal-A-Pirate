local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Frame = require(ReplicatedStorage.Shared.Modules.Components.UI.Frame)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local InteractButton = require(ReplicatedStorage.Shared.Modules.Components.UI.InteractButton)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function BaseSelect(
	scope: Fusion.Scope<any>,
	props: {
		displayName: UsedAs<string>,
		select: () -> (),
	}
): Fusion.Child
	local target = scope:Value()
	local frame = Frame(scope, {
		size = UDim2.fromScale(1, 0.1),
		children = {
			Text(scope, {
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(1, 0.5),

				textXAlignment = Enum.TextXAlignment.Center,

				text = props.displayName,
			}),
			InteractButton(scope, {
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.5, 0.5),
				size = UDim2.fromScale(1, 1),

				clicked = props.select,

				animated = target,
			}),
		},
	})
	target:set(frame)
	return frame
end

return BaseSelect
