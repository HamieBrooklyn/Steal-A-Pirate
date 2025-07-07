local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectorBoardTemp = ReplicatedStorage.Assets.Templates.Gui.CollectorBoard

local SharedSpawningTypes = require(ReplicatedStorage.Shared.Modules.Services.SpawningService.Types)

local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function CollectorBoard(
	scope: Fusion.Scope<any>,
	props: {
		Adornee: UsedAs<Instance?>,
		Parent: UsedAs<Instance?>,

		Amount: UsedAs<number>,
	}
): Fusion.Child
	local offsetSpring = scope:Spring(scope:Value(CollectorBoardTemp.StudsOffset), 10, 0.5)
	local board: BillboardGui = scope:Hydrate(CollectorBoardTemp:Clone())({
		Parent = props.Parent,
		Adornee = props.Adornee,

		StudsOffset = offsetSpring,
	})
	local lastAmount = 0

	local amountLabel: TextLabel = board:FindFirstChild("Amount")

	local startTextColor = amountLabel.TextColor3
	local textColor = scope:Value(startTextColor)

	scope:Hydrate(amountLabel)({
		Text = scope:Computed(function(use)
			local amount = use(props.Amount)
			if amount > lastAmount then
				offsetSpring:addVelocity(Vector3.yAxis * 5)
				textColor:set(Color3.fromRGB(255, 251, 0))
				task.delay(0.25, function()
					textColor:set(startTextColor)
				end)
			end
			lastAmount = amount
			return `${abbreviateNumber(amount)}`
		end),
		TextColor3 = scope:Spring(textColor, 25, 0.5),
	})
	return board
end

return CollectorBoard
