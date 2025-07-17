local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PromptTemplate = ReplicatedStorage.Assets.Templates.Gui.Prompt

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local OnEvent = Fusion.OnEvent
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function PromptBoard(
	scope: Fusion.Scope<any>,
	props: {
		Shown: UsedAs<boolean>,
		Adornee: UsedAs<Instance>,

		ActionText: UsedAs<string>,
		ObjectText: UsedAs<string>,

		HoldDuration: UsedAs<number>,
		Holding: UsedAs<boolean>,

		startHolding: () -> (),
		endHolding: () -> (),
	}
)
	local promptBoard: typeof(PromptTemplate) = scope:Hydrate(PromptTemplate:Clone())({
		Size = scope:Spring(
			scope:Computed(function(use)
				return use(props.Shown) and PromptTemplate.Size or UDim2.new()
			end),
			25,
			0.5
		),
		Enabled = props.Shown,
		Adornee = props.Adornee,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
	})

	local mainFrame = promptBoard:WaitForChild("Main")
	scope:Hydrate(mainFrame:WaitForChild("ActionText"))({
		Text = props.ActionText,
	})
	scope:Hydrate(mainFrame:WaitForChild("ObjectText"))({
		Text = props.ObjectText,
	})
	scope:Hydrate(mainFrame:WaitForChild("Interact"))({
		[OnEvent("MouseButton1Down")] = props.startHolding,
		[OnEvent("MouseButton1Up")] = props.endHolding,
	})
	mainFrame:WaitForChild("Icon").Image = UserInputService.TouchEnabled and "rbxassetid://103847203345625"
		or "rbxassetid://91160084996241"

	local transparencyProgress = scope:Value(0)
	local holdDuration = scope:Value(peek(props.HoldDuration))
	local transparencyTween = scope:Tween(
		transparencyProgress,
		scope:Computed(function(use)
			return TweenInfo.new(use(holdDuration))
		end)
	)
	local holdOutline: UIStroke = mainFrame:WaitForChild("Icon"):WaitForChild("HoldOutline")
	local gradient = holdOutline:FindFirstChildOfClass("UIGradient")
	local function updateGradient(progress: number)
		gradient.Transparency = progress == 0 and NumberSequence.new(1, 1)
			or NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(math.clamp(progress - 0.05, 0, 0.99), 0),
				NumberSequenceKeypoint.new(progress, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
	end
	local holdingCon: RBXScriptConnection?
	scope:Observer(props.Holding):onBind(function()
		if peek(props.HoldDuration) == 0 then
			return
		end
		if holdingCon then
			holdingCon:Disconnect()
			holdingCon = nil
		end

		local holdingState = peek(props.Holding)
		transparencyProgress:set(holdingState and 1 or 0)
		holdDuration:set(holdingState and peek(props.HoldDuration) or 0.5)

		holdingCon = RunService.Heartbeat:Connect(function()
			local progress = peek(transparencyTween)
			updateGradient(progress)
			holdOutline.Enabled = progress > 0.05
			if (holdingState and progress >= 1) or (not holdingState and progress == 0) then
				holdingCon:Disconnect()
				holdingCon = nil
				transparencyProgress:set(0)
			end
		end)
	end)

	return promptBoard
end

return PromptBoard
