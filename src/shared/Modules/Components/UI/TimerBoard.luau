local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

export type UsedAs<T> = Fusion.UsedAs<T>

local function TimerBoard(
	scope: Fusion.Scope,
	props: {
		secondsLeft: UsedAs<number>,
		adornee: UsedAs<Instance?>,
	}
)
	return scope:New("BillboardGui")({
		Name = "InvisibleTimer",
		Size = UDim2.fromScale(5, 2),
		StudsOffset = Vector3.new(0, 5, 0),
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
		Adornee = props.adornee,
		[Fusion.Children] = Text(scope, {
			size = UDim2.fromScale(1, 1),
			text = scope:Computed(function(use)
				return formatTime(use(props.secondsLeft), {
					mode = "text",
					showDays = false,
					showHours = false,
					showMinutes = false,
					showSeconds = true,
					showMilliseconds = true,
				})
			end),
		}),
	})
end

return TimerBoard
