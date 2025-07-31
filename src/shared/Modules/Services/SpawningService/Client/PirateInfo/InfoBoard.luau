local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PirateInfoBoard = ReplicatedStorage.Assets.Templates.Gui.PirateInfo

local SharedRaritiesData = require(ReplicatedStorage.Shared.Modules.Data.Rarities)
local SharedSpawningData = require(Services.SpawningService.Data)
local SharedTypes = require(script.Parent.Parent.Parent.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Text = require(ReplicatedStorage.Shared.Modules.Components.UI.Text)
local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs<T>

local function InfoBoard(
	scope: Fusion.Scope<any>,
	props: {
		Parent: UsedAs<Instance>,
		Adornee: UsedAs<Instance>,

		StudsOffset: UsedAs<Vector3>,

		Mutations: UsedAs<{ string }>,
		Name: UsedAs<string>,
		Data: UsedAs<SharedTypes.CharacterData>,
	}
)
	local board: BillboardGui = scope:Hydrate(PirateInfoBoard:Clone())({
		Parent = props.Parent,
		Adornee = props.Adornee,
		StudsOffset = props.StudsOffset,
	})

	local contentsFrame: Frame = board:FindFirstChild("Contents")
	contentsFrame:FindFirstChild("Name").Text = props.Name
	contentsFrame:FindFirstChild("Price").Text = `${abbreviateNumber(props.Data.Price)}`

	scope:Hydrate(contentsFrame:FindFirstChild("CashFlow"))({
		Text = scope:Computed(function(use)
			local totalMutMult = 0
			for _, v in use(props.Mutations) do
				totalMutMult += SharedSpawningData.Mutations[v].Mult
			end
			if totalMutMult < 1 then
				totalMutMult += 1
			end
			return `${abbreviateNumber(props.Data.Cashflow * totalMutMult)}/s`
		end),
	})

	local rarityLabel = contentsFrame:FindFirstChild("Rarity")
	rarityLabel.Text = props.Data.Rarity
	rarityLabel.TextColor3 = SharedRaritiesData.Info[props.Data.Rarity].PrimaryColor

	scope:New("BillboardGui")({
		ResetOnSpawn = false,
		Adornee = props.Adornee,
		Parent = props.Parent,
		StudsOffset = props.StudsOffset + Vector3.new(0, 6.5, 0),
		AlwaysOnTop = true,
		Size = UDim2.fromScale(12, 10),
		[Children] = scope:New("Frame")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			[Children] = {
				scope:New("UIListLayout")({
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
				}),
				scope:ForValues(props.Mutations, function(_, mutScope: Fusion.Scope<any>, mutName: string)
					local mutData = SharedSpawningData.Mutations[mutName]

					local text = Text(mutScope, {
						size = UDim2.fromScale(1, 0.25),
						text = `{mutData.Title} [x{mutData.Mult}]`,
					})

					local gradient = mutData.Gradient:Clone()
					gradient.Parent = text
					gradient:AddTag("AnimatedGradient")

					return text
				end),
			},
		}),
	})

	return board
end

return InfoBoard
