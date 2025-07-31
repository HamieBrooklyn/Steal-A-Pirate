local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CharacterModels = ReplicatedStorage.Assets.Models.Characters
local Services = ReplicatedStorage.Shared.Modules.Services

local MenuClient = require(Services.MenuService.Client)

local SharedRaritiesData = require(ReplicatedStorage.Shared.Modules.Data.Rarities)
local SharedSpawningData = require(Services.SpawningService.Data)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local CharacterView = require(script.CharacterView)

local Hydrate, Children, ForPairs, Value, Observer, Tween, Computed =
	Fusion.Hydrate, Fusion.Children, Fusion.ForPairs, Fusion.Value, Fusion.Observer, Fusion.Tween, Fusion.Computed
local peek = Fusion.peek

local function IndexMenu(
	scope: Fusion.Scope<any>,
	props: {
		unlockedCharacterNames: Fusion.Value<{ string }, any>,
		charactersUnlockedCount: Fusion.Value<number, any>,

		putOnDisplayAttempt: (pirateName: string) -> (),
	}
)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local indexGui = playerGui:WaitForChild("Index")
	local mainFrame = indexGui:WaitForChild("Main")
	local progressLabel = mainFrame:WaitForChild("Progress")
	local contents = mainFrame:WaitForChild("Contents")

	local charactersOwned = Value(scope, 0)
	local amountTween = Tween(scope, charactersOwned, TweenInfo.new(0.5))
	Hydrate(scope, progressLabel)({
		Text = Computed(scope, function(use)
			local max = 0
			for _, v in SharedSpawningData.Characters.Info do
				if v.Natural == nil or v.Natural == true then
					max += 1
				end
			end
			return `{math.floor(use(amountTween))}/{max}`
		end),
	})

	table.insert(
		scope,
		MenuClient.ObserveMenu("Index", function(menu)
			local shown = Value(scope, false)
			Observer(scope, menu.opened):onBind(function()
				local openedState = peek(menu.opened)
				charactersOwned:set(openedState and peek(props.charactersUnlockedCount) or 0)
				shown:set(openedState)
			end)
			-- local function UpdateCanvasSize(Canvas, Constraint)
			-- 	Canvas.CanvasSize =
			-- 		UDim2.new(0, Constraint.AbsoluteContentSize.X, 0, Constraint.AbsoluteContentSize.Y - 100)
			-- end
			-- UpdateCanvasSize(contents, contents:FindFirstChildOfClass("UIGridLayout"))

			Hydrate(scope, contents)({
				[Children] = ForPairs(
					scope,
					props.unlockedCharacterNames,
					function(_, indexScope: Fusion.Scope<any>, characterName: string, unlocked: boolean)
						local rarity = SharedSpawningData.Characters.Info[characterName].Rarity
						return characterName,
							CharacterView(indexScope, {
								shown = shown,
								unlocked = unlocked,
								characterName = characterName,

								viewportModel = CharacterModels:FindFirstChild(characterName),

								strokeColor = SharedRaritiesData.Info[rarity].PrimaryColor,
								isUnknownRarity = rarity == "Unknown",

								interact = props.putOnDisplayAttempt,
							})
					end
				),
			})
		end)
	)
end

return IndexMenu
