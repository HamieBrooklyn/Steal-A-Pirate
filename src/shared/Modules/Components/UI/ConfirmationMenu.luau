local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Frame = require(ReplicatedStorage.Shared.Modules.Components.UI.Frame)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local Button = require(script.Parent.Button)

local Children = Fusion.Children
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function ConfirmationMenu(
	scope: Fusion.Scope<any>,
	props: {
		parent: UsedAs<PlayerGui?>,

		infoText: UsedAs<string>,
		confirmText: UsedAs<string>,
		exitText: UsedAs<string>,

		confirmColor: UsedAs<Color3?>,
		exitColor: UsedAs<Color3?>,

		confirmed: () -> (),
		exited: (() -> ())?,
	}
): Fusion.Child
	local mainTarget = scope:Value()
	local shown = scope:Value(false)
	local main = scope:New("ScreenGui")({
		Name = "Confirm",
		ResetOnSpawn = true,
		Parent = props.parent,

		[Children] = scope:New("CanvasGroup")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = scope:Spring(
				scope:Computed(function(use)
					return use(shown) and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.55)
				end),
				25,
				0.7
			),
			Size = UDim2.fromScale(0.3, 0.25),

			BackgroundTransparency = 1,
			GroupTransparency = scope:Tween(
				scope:Computed(function(use)
					return use(shown) and 0 or 1
				end),
				TweenInfo.new(0.2)
			),

			[Children] = {
				scope:New("UIPadding")({
					PaddingTop = UDim.new(0.05),
					PaddingBottom = UDim.new(0.05),
					PaddingLeft = UDim.new(0.05),
					PaddingRight = UDim.new(0.05),
				}),
				Frame(scope, {
					size = UDim2.fromScale(1, 1),
				}),
				Text(scope, {
					anchorPoint = Vector2.new(0.5, 0),
					position = UDim2.fromScale(0.5, 0),
					size = UDim2.fromScale(1, 0.4),

					text = props.infoText,
					richText = true,
				}),
				Button(scope, {
					text = props.exitText,
					callback = function()
						peek(mainTarget):Destroy()
						if props.exited then
							props.exited()
						end
					end,

					Position = UDim2.fromScale(0.25, 0.7),
					BackgroundColor = props.exitColor or Color3.fromHex("#AEAEAE"),
				}),
				Button(scope, {
					text = props.confirmText,
					callback = function()
						peek(mainTarget):Destroy()
						props.confirmed()
					end,

					Position = UDim2.fromScale(0.75, 0.7),
					BackgroundColor = props.confirmColor or Color3.fromRGB(6, 255, 106),
				}),
			},
		}),
	})
	shown:set(true)
	mainTarget:set(main)
	return main
end

return ConfirmationMenu
