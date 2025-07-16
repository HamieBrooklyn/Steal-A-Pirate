local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashMultBoardTemp = ReplicatedStorage.Assets.Templates.Gui.CashMultInfo

local Fusion = require(ReplicatedStorage.Packages.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function CashMultBoard(
	scope: Fusion.Scope<any>,
	props: {
		text: UsedAs<string>,

		adornee: UsedAs<Instance?>,
		parent: UsedAs<Instance?>,
	}
)
	local board: typeof(CashMultBoardTemp) = scope:Hydrate(CashMultBoardTemp:Clone())({
		Adornee = props.adornee,
		Parent = props.parent,
	})

	scope:Hydrate(board:WaitForChild("Amount"))({
		Text = props.text,
	})

	return board
end

return CashMultBoard
