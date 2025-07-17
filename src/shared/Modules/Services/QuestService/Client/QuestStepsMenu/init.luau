local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local StepText = require(script.StepText)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function init(
	scope: Fusion.Scope<any>,
	props: {
		stepText: UsedAs<string>,
		stepTextShown: UsedAs<boolean>,
	}
): Fusion.Child
	return scope:New("ScreenGui")({
		Name = "QuestStep",
		ResetOnSpawn = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),

		[Children] = StepText(scope, {
			text = props.stepText,
			shown = props.stepTextShown,
		}),
	})
end

return init
