local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local ChoicesSurfaceBoardTemp = ReplicatedStorage.Assets.Templates.Gui.DonaionLeaderboardChoices

local MonitizationClient = require(Services.MonitizationService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Hydrate = Fusion.Hydrate

type UsedAs<T> = Fusion.UsedAs<T>

local function ChoicesBoard(
	scope: Fusion.Scope<any>,
	props: {
		parent: UsedAs<Instance?>,
		adornee: UsedAs<Instance?>,
	}
)
	local board: typeof(ChoicesSurfaceBoardTemp) = Hydrate(scope, ChoicesSurfaceBoardTemp:Clone())({
		Parent = props.parent,
		Adornee = props.adornee,
	})

	for _, v in board:WaitForChild("Contents"):GetChildren() do
		local id = v:GetAttribute("ID")
		if id then
			v.MouseButton1Click:Connect(function()
				MonitizationClient.SetPrompting(tonumber(id))
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, tonumber(id))
			end)
		end
	end

	return board
end

return ChoicesBoard
