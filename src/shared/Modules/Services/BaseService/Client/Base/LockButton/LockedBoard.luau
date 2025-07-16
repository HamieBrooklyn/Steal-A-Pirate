local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseLockBoardTemp = ReplicatedStorage.Assets.Templates.Gui.BaseLockInfo

local SharedData = require(script.Parent.Parent.Parent.Parent.Data)

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function LockedBoard(
	scope: Fusion.Scope<any>,
	props: {
		parent: UsedAs<Instance?>,
		adornee: UsedAs<Instance?>,

		secondsLeft: UsedAs<number>,
	}
)
	local board: BillboardGui = scope:Hydrate(BaseLockBoardTemp:Clone())({
		ResetOnSpawn = false,
		Adornee = props.adornee,
		Parent = props.parent,
	})

	scope:Hydrate(board:WaitForChild("Status"))({
		Text = scope:Computed(function(use)
			return use(props.secondsLeft) == 0 and "Lock Base!"
				or `LOCKED {formatTime(use(props.secondsLeft), { mode = "text" })}`
		end),
		TextColor3 = scope:Computed(function(use)
			return use(props.secondsLeft) == 0 and SharedData.BaseLockBoard.UnlockedColor
				or SharedData.BaseLockBoard.LockedColor
		end),
	})

	return board
end

return LockedBoard
