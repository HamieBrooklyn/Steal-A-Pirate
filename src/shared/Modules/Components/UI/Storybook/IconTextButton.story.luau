local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconTextButton = require(ReplicatedStorage.Shared.Modules.Components.UI.IconTextButton)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return {
	story = function()
		local scope = Fusion.scoped(Fusion)
		return IconTextButton(scope, {
			text = "Hello!",
			icon = "rbxassetid://131533975492593",

			backgroundColor = Color3.fromHex("#6effad"),
			textColor = Color3.new(1, 1, 1),
			outlineColor = Color3.new(0, 0, 0),

			native = {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(120, 45),
			},
		})
	end,
}
