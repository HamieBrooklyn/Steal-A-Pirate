local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(script.Parent.Parent.Types)

local Setting = require(script.Setting)
local TopBar = require(script.TopBar)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Children, ForPairs, Value = Fusion.New, Fusion.Children, Fusion.ForPairs, Fusion.Value

type UsedAs<T> = Fusion.UsedAs<T>

local function SettingsMenu(
	scope: Fusion.Scope<any>,
	props: {
		settingsData: UsedAs<{ SharedTypes.SettingData }>,
		playerSettings: { [number]: { [string]: any } },
		setSetting: (...any) -> (),
	}
): Fusion.Child
	local mainFrameTarget = Value(scope, nil)
	local mainFrame = New(scope, "Frame")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.62, 0.62),

		BackgroundTransparency = 0.75,
		BackgroundColor3 = Color3.new(0, 0, 0),

		[Children] = {
			New(scope, "UIPadding")({
				PaddingRight = UDim.new(0.01, 0),
				PaddingLeft = UDim.new(0.01, 0),
				PaddingBottom = UDim.new(0.05, 0),
				PaddingTop = UDim.new(0.05, 0),
			}),
			New(scope, "UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.05, 0),
			}),
			New(scope, "UIStroke")({}),
			New(scope, "UICorner")({ CornerRadius = UDim.new(0.1, 0) }),
			scope:New("UIAspectRatioConstraint")({}),
			TopBar(scope, { mainFrame = mainFrameTarget }),
			ForPairs(
				scope,
				props.settingsData,
				function(_, settingScope: Fusion.Scope<any>, index: string, data: SharedTypes.SettingData)
					return Setting(settingScope, index, {
						settingData = data,
						value = props.playerSettings[index],

						update = function(...)
							props.setSetting(index, ...)
						end,
					})
				end
			),
		},
	})
	mainFrameTarget:set(mainFrame)

	return mainFrame
end

return SettingsMenu
