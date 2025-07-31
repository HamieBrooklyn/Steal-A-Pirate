local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local InteractButton = require(ReplicatedStorage.Shared.Modules.Components.UI.InteractButton)
local CharacterViewport = require(ReplicatedStorage.Shared.Modules.Classes.CharacterViewport)
local ViewportFitter = require(ReplicatedStorage.Packages.ViewportFitter)
local Viewport = require(ReplicatedStorage.Shared.Modules.Components.UI.Viewport)

local Children = Fusion.Children
local peek = Fusion.peek

export type CachedSpawnProps = {
	canInteract: UsedAs<boolean>,

	pirateName: UsedAs<string>,

	spawnAttempt: () -> (),
}

type UsedAs<T> = Fusion.UsedAs<T>

local function CachedSpawn(scope: Fusion.Scope<any>, props: CachedSpawnProps): Fusion.Child
	local frameTarget: Fusion.Value<Frame?> = scope:Value()
	local frame = scope:New("Frame")({
		Size = UDim2.fromScale(0.8, 0.1),

		BackgroundTransparency = 1,

		[Children] = {
			Ratio = scope:New("UIAspectRatioConstraint")({}),
			Stroke = scope:New("UIStroke")({
				Color = scope:Tween(
					scope:Computed(function(use: Fusion.Use)
						return use(props.canInteract) and Color3.new(1, 1, 1) or Color3.new(1, 0, 0)
					end),
					TweenInfo.new(0.5)
				),
			}),
			Corner = scope:New("UICorner")({}),
			View = Viewport(scope, {
				model = ReplicatedStorage.Assets.Models.Characters:FindFirstChild(props.pirateName),
				native = {
					Size = UDim2.fromScale(1, 1),
				},
			}),
			Interact = InteractButton(scope, {
				size = UDim2.fromScale(1, 1),
				clicked = props.spawnAttempt,
				interactable = props.canInteract,
				animated = frameTarget,
			}),
		},
	})
	frameTarget:set(frame)

	return frame
end

return CachedSpawn
