local ReplicatedStorage = game:GetService("ReplicatedStorage")

local joinTables = require(ReplicatedStorage.Shared.Modules.Utilities.joinTables)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children

export type ViewportProps = {
	model: UsedAs<Model>,

	native: { string },
	[typeof(Children)]: Fusion.Children,
}

type UsedAs<T> = Fusion.UsedAs<T>

local function Viewport(scope: Fusion.Scope, props: ViewportProps): Fusion.Child
	local vieportTarget: Fusion.Value<ViewportFrame?> = scope:Value()
	local model: Model = scope:Hydrate(props.model:Clone())({
		Parent = vieportTarget,
	})
	model:PivotTo(CFrame.new() * CFrame.Angles(0, math.rad(180), 0))
	local camera = scope:New("Camera")({
		Parent = vieportTarget,
		CFrame = CFrame.new(0, 0, 10),
	})
	local viewport = scope:New("ViewportFrame")(joinTables({
		BackgroundTransparency = 1,
		CurrentCamera = camera,
		[Children] = {
			props[Children],
		},
	}, props.native))
	vieportTarget:set(viewport)
	return viewport
end

return Viewport
