local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local joinTables = require(ReplicatedStorage.Shared.Modules.Utilities.joinTables)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local SquareIcon = require(ReplicatedStorage.Shared.Modules.Components.UI.SquareIcon)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

export type SlotInfo = {
	Title: UsedAs<string>,
	Image: UsedAs<string>,
	BottomText: UsedAs<number>,
}

export type SlotProps = {
	native: UsedAs<{ [string]: any }>,
	info: UsedAs<SlotInfo>,
}

local function Slot(scope: Fusion.Scope<any>, props: SlotProps): Fusion.Child
	return scope:New("Frame")(joinTables({
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.25, 0.4),

		BackgroundTransparency = 1,

		[Children] = {
			Text(scope, {
				anchorPoint = Vector2.new(0.5, 0),
				position = UDim2.fromScale(0.5, 0.05),
				size = UDim2.fromScale(1, 0.2),

				text = props.info.Title,
			}),
			SquareIcon(scope, {
				anchorPoint = Vector2.new(0.5, 0),
				position = UDim2.fromScale(0.5, 0.3),
				size = UDim2.fromScale(1, 0.4),

				image = props.info.Image,
			}),
			Text(scope, {
				anchorPoint = Vector2.new(0.5, 0),
				position = UDim2.fromScale(0.5, 0.65),
				size = UDim2.fromScale(0.9, 0.2),

				text = props.info.BottomText,
			}),
		},
	}, props.native))
end

return Slot
