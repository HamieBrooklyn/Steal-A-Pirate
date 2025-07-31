local ReplicatedStorage = game:GetService("ReplicatedStorage")

local joinTables = require(ReplicatedStorage.Shared.Modules.Utilities.joinTables)

local Slot = require(script.Slot)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local SquareIcon = require(ReplicatedStorage.Shared.Modules.Components.UI.SquareIcon)
local TextButton = require(ReplicatedStorage.Shared.Modules.Components.UI.TextButton)
local PaySpinButton = require(script.PaySpinButton)
local Spinner = require(ReplicatedStorage.Shared.Modules.Services.SpinnerService.Client.SpinMenu.Spinner)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

export type SpinMenuProps = {
	native: UsedAs<{ [string]: any }>,
	slots: UsedAs<{ Slot.SlotInfo }>,

	spinsText: UsedAs<string>,
	canSpin: UsedAs<boolean>,
	rotation: UsedAs<number>,
	arrowRotation: UsedAs<number>,

	promptSpinPurchase: (id: number) -> (),
	spinAttempt: () -> (),
}

local function SpinMenu(scope: Fusion.Scope<any>, props: SpinMenuProps): Fusion.Child
	return scope:New("Frame")(joinTables({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.65, 0.65),

		BackgroundTransparency = 1,

		[Children] = {
			SquareIcon(scope, {
				anchorPoint = Vector2.new(0.5, 0),
				position = UDim2.fromScale(0.5, 0.2),
				size = UDim2.fromScale(0.07, 0.07),
				rotation = props.arrowRotation,

				image = "rbxassetid://111967540488535",

				ZIndex = 2,
			}),
			Spinner(scope, {
				rotation = props.rotation,
				slots = props.slots,
			}),
			TextButton(scope, {
				text = props.spinsText,

				backgroundColor = scope:Computed(function(use: Fusion.Use)
					return use(props.canSpin) and Color3.fromHex("#6effad") or Color3.fromHex("#969696")
				end),

				clicked = props.spinAttempt,

				native = {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.8),
					Size = UDim2.fromScale(0.1, 0.05),

					Interactable = scope:Computed(function(use: Fusion.Use)
						return use(props.canSpin)
					end),
				},
			}),
			PaySpinButton(scope, {
				text = "\u{E002} 49",
				getText = "Get 1",

				clicked = function()
					props.promptSpinPurchase(3344943564)
				end,

				native = {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(0.44, 0.8),
					Size = UDim2.fromScale(0.1, 0.05),
				},
			}),
			PaySpinButton(scope, {
				text = "\u{E002} 199",
				getText = "Get 3",

				clicked = function()
					props.promptSpinPurchase(3344943442)
				end,

				native = {
					AnchorPoint = Vector2.new(0, 0),
					Position = UDim2.fromScale(0.56, 0.8),
					Size = UDim2.fromScale(0.1, 0.05),
				},
			}),
		},
	}, props.native))
end

return SpinMenu
