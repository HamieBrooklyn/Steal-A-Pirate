local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local Base = require(Services.BaseService.Client.Base)

local Frame = require(ReplicatedStorage.Shared.Modules.Components.UI.Frame)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local BaseSelect = require(script.BaseSelect)

local Children = Fusion.Children
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function UnlockMenu(
	scope: Fusion.Scope<any>,
	props: {
		playerBases: { Base.Base },
		baseSelected: () -> (),
	}
): Fusion.Child
	return scope:New("ScreenGui")({
		Name = "Unlock",
		[Children] = Frame(scope, {
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.3, 0.5),

			children = {
				scope:New("ScrollingFrame")({
					Size = UDim2.fromScale(1, 0.85),
					Position = UDim2.fromScale(0, 0.15),

					BackgroundTransparency = 1,

					[Children] = {
						scope:New("UIListLayout")({
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
						}),
						scope:New("UIPadding")({
							PaddingLeft = UDim.new(0.1),
							PaddingRight = UDim.new(0.1),
							PaddingTop = UDim.new(0.01),
						}),
						scope:ForValues(props.playerBases, function(_, baseScope: Fusion.Scope<any>, base: Base.Base)
							return BaseSelect(baseScope, {
								displayName = Players:GetPlayerByUserId(peek(base.Owner)).DisplayName,
								select = function()
									props.baseSelected(base)
								end,
							})
						end),
					},
				}),
			},
		}),
	})
end

return UnlockMenu
