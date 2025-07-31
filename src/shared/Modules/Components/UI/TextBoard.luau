local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local joinTables = require(ReplicatedStorage.Shared.Modules.Utilities.joinTables)

local Children = Fusion.Children

export type TextBoardProps = {
	adornee: UsedAs<Instance>,
	text: UsedAs<string>,
	textColor: UsedAs<Color3>,

	native: { string },
	[typeof(Children)]: Fusion.Children,
}

type UsedAs<T> = Fusion.UsedAs<T>

local function TextBoard(scope: Fusion.Scope, props: TextBoardProps): Fusion.Child
	return scope:New("BillboardGui")(joinTables({
		Adornee = props.adornee,

		ResetOnSpawn = false,

		LightInfluence = 0,
		Brightness = 10,

		[Children] = {
			Text(scope, {
				size = UDim2.fromScale(1, 1),
				text = props.text,
				textColor = props.textColor,
			}),
			props[Children],
		},
	}, props.native))
end

return TextBoard
