local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local CharacterModels = Assets.Models.Characters

local RebirthItemTemp = Assets.Templates.Gui.Rebirth.Character

local ViewportFitter = require(ReplicatedStorage.Packages.ViewportFitter)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function CharacterFrame(
	scope: Fusion.Scope<any>,
	props: {
		characterName: UsedAs<string>,
		owned: UsedAs<boolean>,
		shown: UsedAs<boolean>,
	}
)
	local frameStartSize = RebirthItemTemp.Size
	local frame: Frame = scope:Hydrate(RebirthItemTemp:Clone())({
		Size = scope:Tween(
			scope:Computed(function(use)
				return use(props.shown) and frameStartSize or UDim2.new()
			end),
			TweenInfo.new(0.25)
		),
	})

	-- Setting character name:
	local nameLabel: TextLabel = frame:WaitForChild("Name")
	scope:Hydrate(nameLabel)({
		Text = scope:Computed(function()
			return props.characterName
		end),
		TextColor3 = scope:Computed(function(use)
			return use(props.owned) and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
		end),
	})

	-- Setting viewport:
	local characterModel: Model = CharacterModels:FindFirstChild(props.characterName):Clone()
	characterModel:PivotTo(CFrame.new())

	local camera = Instance.new("Camera")

	local viewport: ViewportFrame = frame:WaitForChild("View", camera)
	viewport.CurrentCamera = camera

	camera.Parent = viewport
	characterModel.Parent = viewport

	local fitter = ViewportFitter.new(viewport, camera)
	table.insert(scope, fitter)

	fitter:SetModel(characterModel)
	camera.CFrame = fitter:GetMinimumFitCFrame(CFrame.new(0, 1.5, 2) * CFrame.Angles(0, math.rad(180), 0))
	fitter:Calibrate()

	return frame
end

return CharacterFrame
