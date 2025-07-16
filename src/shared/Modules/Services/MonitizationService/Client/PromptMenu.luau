local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Spring, Tween, Computed, Children, Value =
	Fusion.New, Fusion.Spring, Fusion.Tween, Fusion.Computed, Fusion.Children, Fusion.Value
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function PromptMenu(
	scope: Fusion.Scope<any>,
	props: {
		promptingId: UsedAs<number>,
	}
)
	local incrementingRotation = Value(scope, 0)
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function(dt)
			incrementingRotation:set((peek(incrementingRotation) + 1))
		end)
	)
	return New(scope, "CanvasGroup")({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = Tween(
			scope,
			Computed(scope, function(use)
				return use(props.promptingId) ~= -1 and 0 or 1
			end),
			TweenInfo.new(0.5)
		),
		[Children] = {
			New(scope, "Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
				BackgroundTransparency = 0.5,
				[Children] = New(scope, "UIGradient")({
					Color = ColorSequence.new(Color3.fromRGB(255, 156, 74), Color3.fromRGB()),
					Rotation = incrementingRotation,
				}),
			}),
			New(scope, "ImageLabel")({
				AnchorPoint = Vector2.one * 0.5,
				Position = UDim2.fromScale(0.5, 0.15),
				Size = UDim2.fromScale(0.2, 0.2),
				Rotation = incrementingRotation,

				BackgroundTransparency = 1,
				ImageTransparency = 0.5,

				Image = "rbxassetid://95431402015008",

				[Children] = New(scope, "UIAspectRatioConstraint")({}),
			}),
		},
	})
end

return PromptMenu
