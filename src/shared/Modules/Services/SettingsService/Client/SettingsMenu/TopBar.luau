local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SquareIcon = require(ReplicatedStorage.Shared.Modules.Components.UI.SquareIcon)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local CloseButton = require(ReplicatedStorage.Shared.Modules.Components.UI.CloseButton)

local New, Children = Fusion.New, Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function TopBar(
	scope: Fusion.Scope<any>,
	props: {
		mainFrame: UsedAs<Frame?>,
	}
): Fusion.Child
	return New(scope, "Frame")({
		Size = UDim2.fromScale(1, 0.12),

		BackgroundTransparency = 1,

		[Children] = {
			SquareIcon(scope, {
				size = UDim2.fromScale(0.2, 1),
				image = "rbxassetid://95239433408576",
				layoutOrder = 0,
			}),
			Text(scope, {
				position = UDim2.fromScale(0.1, 0),
				size = UDim2.fromScale(0.82, 1),
				text = "Settings",
				textXAlignment = Enum.TextXAlignment.Left,
				layoutOrder = 1,
			}),
			CloseButton(scope, {
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.92, 0.5),
				size = UDim2.fromScale(0.1, 0.8),
				target = props.mainFrame,
				layoutOrder = 2,
			}),
		},
	})
end

return TopBar
