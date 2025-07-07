local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Icon = require(script.Icon)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New, Value, Children = Fusion.New, Fusion.Value, Fusion.Children
local peek = Fusion.peek

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local ScreenIconSpawner = {}
ScreenIconSpawner.__index = ScreenIconSpawner

export type ScreenIconSpawner = typeof(setmetatable({} :: self, ScreenIconSpawner))
export type ScreenIconSpawnerProps = {
	Icons: { [string]: number },
	WorldPart: UsedAs<BasePart>?,
	StartPosition: UsedAs<UDim2>?,
	TargetPosition: UsedAs<UDim2>,
	Speed: number?,
}
type UsedAs<T> = Fusion.UsedAs<T>
type self = {
	_scope: Fusion.Scope<any>,
}

function ScreenIconSpawner.new(
	scope: Fusion.Scope<any>?,
	props: ScreenIconSpawnerProps,
	iconReachedTarget: (() -> ())?,
	finished: (() -> ())?
): ScreenIconSpawner
	local self: ScreenIconSpawner = setmetatable({}, ScreenIconSpawner)

	scope = scope or Fusion.scoped(Fusion)
	props.Speed = props.Speed or 1

	local Random = Random.new()

	local activeIcons = Value(scope, {})
	local container = New(scope, "ScreenGui")({
		Name = "AnimatedScreenIcons",
		Parent = player:WaitForChild("PlayerGui"),
		ResetOnSpawn = false,
		[Children] = activeIcons,
	})
	task.spawn(function()
		for image, amount in props.Icons do
			for i = 1, amount do
				local screenPos: UDim2?
				local worldPart = props.WorldPart
				if worldPart then
					local screenPoint, onScreen = camera:WorldToViewportPoint(worldPart.Position)
					local viewportSize = camera.ViewportSize
					screenPos = UDim2.fromScale(screenPoint.X / viewportSize.X, screenPoint.Y / viewportSize.Y)
				end

				local Position = screenPos and Value(scope, screenPos) or props.StartPosition
				Position:set(
					peek(Position) + UDim2.fromScale(Random:NextNumber(-0.1, 0.1), Random:NextNumber(-0.1, 0.1))
				)
				local Size = Value(scope, UDim2.new())
				local Rotation = Value(scope, 0)

				local newIcon = Icon(scope, {
					Image = image,
					Position = scope:Spring(Position, 5 * props.Speed, 0.8),
					Size = scope:Spring(Size, 25 * props.Speed, 0.5),
					Rotation = scope:Tween(Rotation, TweenInfo.new(1.3 / props.Speed, Enum.EasingStyle.Back)),
				})

				Rotation:set(math.random(-45, 45))

				local state = table.clone(Fusion.peek(activeIcons))
				table.insert(state, newIcon)
				activeIcons:set(state)

				Size:set(UDim2.fromScale(0.08, 0.08))
				--Transparency:set(1)

				task.delay(0.5 / props.Speed, function()
					Size:set(UDim2.new())
				end)

				task.delay((1.3 / props.Speed) / 2, function()
					if iconReachedTarget then
						iconReachedTarget(image)
					end
					local removeAction = table.clone(Fusion.peek(activeIcons))
					table.remove(removeAction, table.find(removeAction, newIcon))
					activeIcons:set(removeAction)
				end)

				task.wait(0.1 / props.Speed)

				Position:set(props.TargetPosition)
			end
		end
		task.delay((1.3 / props.Speed) / 2, function()
			if finished then
				finished()
			end
		end)
	end)

	self._scope = scope

	return self
end

function ScreenIconSpawner.Destroy(self: ScreenIconSpawner)
	Fusion.doCleanup(self._scope)
end

return ScreenIconSpawner
