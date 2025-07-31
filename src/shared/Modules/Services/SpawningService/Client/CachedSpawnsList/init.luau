local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local CachedSpawn = require(script.CachedSpawn)

local Children = Fusion.Children

export type CachedSpawnsListProps = {
	canSpawn: UsedAs<boolean>,
	cachedSpawns: UsedAs<{ string }>,
	spawnAttempt: (pirateName: string) -> (),
}

type UsedAs<T> = Fusion.UsedAs<T>

local function CachedSpawnsList(scope: Fusion.Scope<any>, props: CachedSpawnsListProps): Fusion.Child
	return scope:New("Frame")({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.1, 0.46),
		Size = UDim2.fromScale(0.1, 1),

		BackgroundTransparency = 1,

		[Children] = {
			scope:New("UIListLayout")({
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.05),
			}),
			scope:ForValues(props.cachedSpawns, function(_, spawnScope: Fusion.Scope, pirateName: string)
				return CachedSpawn(spawnScope, {
					canInteract = props.canSpawn,
					pirateName = pirateName,
					spawnAttempt = function()
						props.spawnAttempt(pirateName)
					end,
				})
			end),
		},
	})
end

return CachedSpawnsList
