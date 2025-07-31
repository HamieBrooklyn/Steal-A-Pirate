local ReplicatedStorage = game:GetService("ReplicatedStorage")

local joinTables = require(ReplicatedStorage.Shared.Modules.Utilities.joinTables)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Slot = require(ReplicatedStorage.Shared.Modules.Services.SpinnerService.Client.SpinMenu.Slot)

local Children = Fusion.Children

export type SpinnerProps = {
	rotation: UsedAs<number>,
	slots: UsedAs<{ Slot.SlotInfo }>,

	native: { string },
	[typeof(Children)]: Fusion.Children,
}

type UsedAs<T> = Fusion.UsedAs<T>

local function generateSlotPositions(slotCount, radius)
	local positions = {}
	for i = 1, slotCount do
		local angle = math.rad((360 / slotCount) * (i - 1) - 90)
		local x = 0.5 + radius * math.cos(angle)
		local y = 0.3 + radius * math.sin(angle)
		positions[i] = UDim2.fromScale(x, y)
	end
	return positions
end

local slotPositions = generateSlotPositions(6, 0.3)

local function Spinner(scope: Fusion.Scope, props: SpinnerProps): Fusion.Child
	return scope:New("ImageLabel")(joinTables({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.native and props.native.Size or UDim2.fromScale(0.5, 0.5),
		Rotation = props.rotation,

		BackgroundTransparency = 1,

		Image = "rbxassetid://100376871073882",

		[Children] = {
			scope:New("UIAspectRatioConstraint")({}),
			scope:ForPairs(
				props.slots,
				function(_, slotScope: Fusion.Scope<any>, slotIndex: number, info: Slot.SlotInfo)
					return slotIndex,
						Slot(slotScope, {
							info = info,
							native = {
								Position = slotPositions[slotIndex],
								Rotation = 60 * (slotIndex - 1),
							},
						})
				end
			),
		},
	}, props.native))
end

return Spinner
