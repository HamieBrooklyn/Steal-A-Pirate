local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PirateInfoBoard = ReplicatedStorage.Assets.Templates.Gui.PirateInfo

local SharedRaritiesData = require(ReplicatedStorage.Shared.Modules.Data.Rarities)
local SharedTypes = require(script.Parent.Parent.Parent.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

type UsedAs<T> = Fusion.UsedAs<T>

local function InfoBoard(
	scope: Fusion.Scope<any>,
	props: {
		Parent: UsedAs<Instance>,
		Adornee: UsedAs<Instance>,

		Name: UsedAs<string>,
		Data: UsedAs<SharedTypes.CharacterData>,
	}
)
	local board: BillboardGui = scope:Hydrate(PirateInfoBoard:Clone())({
		Parent = props.Parent,
		Adornee = props.Adornee,
	})

	local contentsFrame: Frame = board:FindFirstChild("Contents")
	contentsFrame:FindFirstChild("Name").Text = props.Name
	contentsFrame:FindFirstChild("Price").Text = props.Data.PriceString
	contentsFrame:FindFirstChild("CashFlow").Text = props.Data.CashflowString

	local rarityLabel = contentsFrame:FindFirstChild("Rarity")
	rarityLabel.Text = props.Data.Rarity
	rarityLabel.TextColor3 = SharedRaritiesData.Info[props.Data.Rarity].PrimaryColor

	return board
end

return InfoBoard
