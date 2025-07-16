local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Gradients = ReplicatedStorage.Assets.Templates.Gui.Gradients

local SharedData = require(script.Parent.Parent.Data)

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Gradiented = require(ReplicatedStorage.Shared.Modules.Classes.Gradiented)

local Hydrate, Value, Spring = Fusion.Hydrate, Fusion.Value, Fusion.Spring

type UsedAs<T> = Fusion.UsedAs<T>

local function FreeCharacterBar(
	scope: Fusion.Scope<any>,
	props: {
		firstSessionTime: UsedAs<number>,
		hasntClaimed: UsedAs<boolean>,
	}
)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local topSide = playerGui:FindFirstChild("Main"):FindFirstChild("HUD"):FindFirstChild("TopSide")
	local freeCharacterProgressFrame = topSide:FindFirstChild("FreeCharacterProgress")
	local progressBar = freeCharacterProgressFrame:FindFirstChild("ProgressBar")
	local timeLabel = progressBar:FindFirstChild("Time")
	local fill = progressBar:FindFirstChild("Fill")

	Hydrate(scope, freeCharacterProgressFrame)({
		Visible = props.hasntClaimed,
	})

	local size = Value(scope, UDim2.fromScale(0, 1))
	Hydrate(scope, fill)({
		Size = Spring(scope, size, 15, 0.9),
	})

	local fillGradient = Gradiented.new(fill, Gradients.Banana)
	local statusGradient = Gradiented.new(timeLabel, Gradiented.Banana)

	local seconds = SharedData.FreeCharacterSeconds
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function()
			local secondsSinceFirstSession = os.time() - props.firstSessionTime
			local secondsLeft = seconds - secondsSinceFirstSession
			size:set(UDim2.fromScale(math.min(secondsSinceFirstSession / seconds, 1), 1))

			local completed = secondsLeft <= 0
			timeLabel.Text = if not completed then formatTime(secondsLeft) else `Use code "AYCE" to claim reward`
			fillGradient.gradient:set(if not completed then Gradients.Banana else Gradients.Apple)
			statusGradient.gradient:set(if not completed then Gradients.Banana else Gradients.Apple)
		end)
	)
end

return FreeCharacterBar
