local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(script.Parent.Parent.Parent.Types)

local ToggleButton = require(script.ToggleButton)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function Setting(
	scope: Fusion.Scope<any>,
	index: number,
	props: {
		settingData: SharedTypes.SettingData,

		value: UsedAs<any>?,

		update: (...any) -> (),
	}
)
	local data = props.settingData
	return index,
		scope:New("Frame")({
			Size = UDim2.fromScale(1, 0.2),

			LayoutOrder = data.Weight,

			BackgroundTransparency = 0.9,
			BackgroundColor3 = Color3.new(),

			[Children] = {
				scope:New("UICorner")({ CornerRadius = UDim.new(0.3, 0) }),
				scope:New("UIStroke")({}),
				scope:New("UIPadding")({
					PaddingLeft = UDim.new(0.02),
					PaddingRight = UDim.new(0.02),
				}),

				Text(scope, {
					anchorPoint = Vector2.new(0, 0.5),
					position = UDim2.fromScale(0, 0.5),
					size = UDim2.fromScale(0.3, 0.65),

					text = data.Title,
				}),
				data.Description and Text(scope, {
					anchorPoint = Vector2.new(0, 0.5),
					position = UDim2.fromScale(0.32, 0.5),
					size = UDim2.fromScale(0.5, 0.5),

					text = data.Description,
				}) or nil,
				data.SettingType == "Toggle" and ToggleButton(scope, { toggled = props.value, clicked = props.update })
					or nil, -- Other setting types here instead of nil, add ( or nil) after new one
			},
		})
end

return Setting
