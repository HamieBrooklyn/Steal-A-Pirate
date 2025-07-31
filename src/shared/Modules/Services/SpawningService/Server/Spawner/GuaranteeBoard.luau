local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedRaritiesData = require(ReplicatedStorage.Shared.Modules.Data.Rarities)

local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function GuaranteeBoard(
	scope: Fusion.Scope<any>,
	props: {
		parent: UsedAs<Instance?>,
		adornee: UsedAs<Instance?>,
		rarityTexts: { [string]: UsedAs<string> },
	}
): Fusion.Child
	return scope:New("BillboardGui")({
		Parent = props.parent,
		Adornee = props.adornee,

		AlwaysOnTop = true,
		ResetOnSpawn = false,
		StudsOffset = Vector3.new(0, 20, 0),
		MaxDistance = 200,

		Size = UDim2.fromScale(30, 25),

		[Children] = scope:New("Frame")({
			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,

			[Children] = {
				scope:New("UIListLayout")({
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0.05, 0),
				}),
				scope:ForPairs(
					props.rarityTexts,
					function(_, rarityScope: Fusion.Scope<any>, rarity: string, text: UsedAs<string>)
						return rarity,
							Text(rarityScope, {
								size = UDim2.fromScale(1, 0.2),
								text = text,
								textColor = SharedRaritiesData.Info[rarity].PrimaryColor,
							})
					end
				),
			},
		}),
	})
end

return GuaranteeBoard
