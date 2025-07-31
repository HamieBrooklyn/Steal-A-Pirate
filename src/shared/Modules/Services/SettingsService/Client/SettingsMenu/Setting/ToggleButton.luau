local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function ToggleButton(
	scope: Fusion.Scope<any>,
	props: {
		anchorPoint: UsedAs<UDim2>,
		position: UsedAs<UDim2>,
		size: UsedAs<UDim2>,

		toggled: UsedAs<boolean>,

		clicked: () -> (),
	}
): Fusion.Child
	local animateTarget: Fusion.Value<GuiObject?, any> = scope:Value(nil)

	local button = scope:New("TextButton")({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		[OnEvent("MouseButton1Click")] = function()
			props.clicked(not peek(props.toggled))
		end,
		[Children] = scope:New("ObjectValue")({
			Name = "Animate",
			Value = animateTarget,
		}),
	})
	button:AddTag("AnimatedButton")
	button:AddTag("AnimatedObject")

	local frame = scope:New("Frame")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.92, 0.5),
		Size = UDim2.fromScale(0.1, 0.3),

		BackgroundTransparency = 0.7,
		BackgroundColor3 = scope:Computed(function(use)
			return use(props.toggled) and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		end),

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			scope:New("UIStroke")({}),
			scope:New("UIPadding")({
				PaddingRight = UDim.new(0.1, 0),
				PaddingLeft = UDim.new(0.1, 0),
				PaddingTop = UDim.new(0.1, 0),
				PaddingBottom = UDim.new(0.1, 0),
			}),

			scope:New("Frame")({
				Size = UDim2.fromScale(1, 1),
				Position = scope:Spring(
					scope:Computed(function(use)
						return use(props.toggled) and UDim2.fromScale(0.7, 0) or UDim2.fromScale(0, 0)
					end),
					25,
					0.7
				),
				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
					scope:New("UIAspectRatioConstraint")({}),
				},
			}),
			button,
		},
	})
	animateTarget:set(frame)

	return frame
end

return ToggleButton
