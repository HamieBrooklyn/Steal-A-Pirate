local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local GuiAnimationClient = require(Services.GuiAnimationService.Client)
local SpawningClient = require(Services.SpawningService.Client)

local CharacterViewTemp = ReplicatedStorage.Assets.Templates.Gui.IndexCharacterView

local ViewportFitter = require(ReplicatedStorage.Packages.ViewportFitter)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Hydrate, Computed, Observer = Fusion.Hydrate, Fusion.Computed, Fusion.Observer
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function CharacterView(
	scope: Fusion.Scope<any>,
	props: {
		shown: UsedAs<boolean>,
		unlocked: UsedAs<boolean>,
		characterName: UsedAs<string>,

		viewportModel: UsedAs<Instance>,

		strokeColor: UsedAs<Color3>,
		isUnknownRarity: UsedAs<boolean>,

		interact: () -> (),
	}
)
	local frame: typeof(CharacterViewTemp) = Hydrate(scope, CharacterViewTemp:Clone())({
		LayoutOrder = table.find(SpawningClient.characterNamesByIndex, peek(props.characterName)),
	})
	local mainFrame = frame:WaitForChild("Main")
	table.insert(
		scope,
		GuiAnimationClient.ObserveAnimatedObject(mainFrame, function(animatedObject)
			Observer(scope, props.shown):onBind(function()
				animatedObject.Size:set(peek(props.shown) and UDim2.fromScale(1, 1) or UDim2.new())
			end)
		end)
	)
	scope:Hydrate(mainFrame:WaitForChild("Interact"))({
		[Fusion.OnEvent("MouseButton1Click")] = function()
			if props.unlocked then
				props.interact(props.characterName)
			end
		end,
	})

	Hydrate(scope, mainFrame:WaitForChild("Name"))({
		Text = Computed(scope, function(use)
			return use(props.unlocked) and use(props.characterName) or "???"
		end),
	})

	local camera = Instance.new("Camera")
	local viewport: ViewportFrame = Hydrate(scope, mainFrame:WaitForChild("View"))({
		ImageColor3 = Computed(scope, function(use)
			return use(props.unlocked) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		end),
		CurrentCamera = camera,
	})
	local stroke = viewport:FindFirstChildOfClass("UIStroke")
	stroke.Color = props.strokeColor

	local unknownGradient = stroke:FindFirstChildOfClass("UIGradient")
	unknownGradient.Enabled = props.isUnknownRarity
	unknownGradient:FindFirstChildOfClass("LocalScript").Enabled = props.isUnknownRarity

	local model: Model = peek(props.viewportModel):Clone()
	model:PivotTo(CFrame.new())

	camera.Parent = viewport
	model.Parent = viewport

	local fitter = ViewportFitter.new(viewport, camera)
	fitter:SetModel(model)

	Observer(scope, props.shown):onBind(function()
		if peek(props.shown) then
			task.delay(0.1, function()
				fitter:Calibrate()
				task.wait(0.1)
				camera.CFrame = fitter:GetMinimumFitCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
			end)
		end
	end)

	return frame
end

return CharacterView
