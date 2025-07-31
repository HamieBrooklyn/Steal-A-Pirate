local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function BasePointer(
	scope: Fusion.Scope<any>,
	props: {
		Parent: UsedAs<Instance>,
		Adornee: UsedAs<Instance>,
	}
): Fusion.Child
	local lastBob = time()
	local studsOffsetSpring: Fusion.Spring = scope:Spring(scope:Value(Vector3.new(0, 70, 0)), 5, 0.5)
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function()
			if time() - lastBob > 2 then
				lastBob = time()
				studsOffsetSpring:addVelocity(Vector3.new(0, 50, 0))
			end
		end)
	)
	return scope:New("BillboardGui")({
		Name = "BasePointer",

		Size = UDim2.fromScale(60, 60),
		StudsOffset = studsOffsetSpring,
		AlwaysOnTop = true,
		ResetOnSpawn = true,

		Parent = props.Parent,
		Adornee = props.Adornee,

		[Children] = {
			Text(scope, {
				anchorPoint = Vector2.new(0.5, 0),
				position = UDim2.fromScale(0.5, 0),
				size = UDim2.fromScale(1, 0.3),

				text = "YOUR BASE",
			}),
			scope:New("ImageLabel")({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(0.7, 0.7),

				Image = "rbxassetid://140068695694747",
				Rotation = -90,

				BackgroundTransparency = 1,

				[Children] = scope:New("UIAspectRatioConstraint")({}),
			}),
		},
	})
end

return BasePointer
