local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectorBoardTemp = ReplicatedStorage.Assets.Templates.Gui.CollectorBoard

local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Charm = require(ReplicatedStorage.Packages.Charm)

local subscribe = Charm.subscribe

type UsedAs<T> = Fusion.UsedAs<T>

local function CollectorBoard(
	scope: Fusion.Scope<any>,
	props: {
		Adornee: UsedAs<Instance?>,
		Parent: UsedAs<Instance?>,

		ownerId: UsedAs<number?>,

		Amount: Charm.Atom<number>,
	}
): Fusion.Child
	local offsetSpring = scope:Spring(scope:Value(CollectorBoardTemp.StudsOffset), 10, 0.5)
	local board: typeof(CollectorBoardTemp) = scope:Hydrate(CollectorBoardTemp:Clone())({
		ResetOnSpawn = false,

		Parent = props.Parent,
		Adornee = props.Adornee,

		StudsOffset = offsetSpring,
	})

	local amountLabel: TextLabel = board:FindFirstChild("Amount")

	local startTextColor = amountLabel.TextColor3
	local textColor = scope:Value(startTextColor)

	scope:Hydrate(board:WaitForChild("Title"))({
		Visible = scope:Computed(function(use)
			return use(props.ownerId) == Players.LocalPlayer.UserId
		end),
	})

	scope:Hydrate(amountLabel)({
		TextColor3 = scope:Spring(textColor, 25, 0.5),
	})
	local function check(state: number, prev: number?)
		amountLabel.Text = `${abbreviateNumber(state)}`
		if prev and state > prev then
			offsetSpring:addVelocity(Vector3.yAxis * 5)
			textColor:set(Color3.fromRGB(255, 251, 0))
			task.delay(0.25, function()
				textColor:set(startTextColor)
			end)
		end
	end
	subscribe(props.Amount, check)
	check(props.Amount())

	return board
end

return CollectorBoard
