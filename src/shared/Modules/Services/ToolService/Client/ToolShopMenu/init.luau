local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedData = require(script.Parent.Parent.Data)
local Types = require(script.Parent.Types)

local MonitizationClient = require(Services.MonitizationService.Client)
local PlayerDataClient = require(Services.PlayerDataService.Client)
local RebirthClient = require(Services.RebirthService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Tool = require(script.Tool)
local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local Children = Fusion.Children
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

local function ToolShopMenu(
	scope: Fusion.Scope<any>,
	props: {
		inventory: Fusion.Value<{ Types.InventoryToolData }>,
		toolInteractAttempt: (toolName: string) -> (),
	}
): Fusion.Child
	local mainFrame = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ToolShop"):WaitForChild("Main")

	scope:Hydrate(mainFrame:WaitForChild("Contents"))({
		[Children] = scope:ForPairs(
			props.inventory,
			function(_, toolScope: Fusion.Scope<any>, toolName: string, data: Types.InventoryToolData)
				local shopData = SharedData.ShopTools[toolName]

				local unlocked = toolScope:Computed(function(use: Fusion.Use)
					local rebirthsRequired = shopData.RebirthsRequired
					local requiresUnlock = shopData.RequiresUnlock == true
					local invData: Types.InventoryToolData = use(props.inventory)[toolName]
					local hasItem = invData.Stock and peek(invData.Stock) > 0
					return use(RebirthClient.rebirths) >= rebirthsRequired
						and (if requiresUnlock then hasItem else true)
						and (if shopData.PassId then hasItem else true)
				end)
				local canInteract = toolScope:Computed(function(use: Fusion.Use)
					local cashCost = shopData.CashCost
					local stockLimit = shopData.Limit or math.huge
					local stock = use(data.Stock)
					-- print(
					-- 	toolName,
					-- 	shopData.PassId ~= nil,
					-- 	peek(unlocked),
					-- 	(if cashCost then use(PlayerDataClient.leaderstats.Cash) >= cashCost else true),
					-- 	stock < stockLimit
					-- )
					return (
						shopData.PassId ~= nil
						and not peek(
							MonitizationClient.playerGamepasses[MonitizationClient.productKeysById[shopData.PassId]]
						)
						and not use(unlocked)
					)
						or (
							use(unlocked)
							and (if cashCost then use(PlayerDataClient.leaderstats.Cash) >= cashCost else true)
							and stock < stockLimit
						)
				end)
				local statusText = toolScope:Computed(function(use: Fusion.Use)
					local equipped = use(data.Equipped)
					local stock = use(data.Stock)
					local stockLimit = shopData.Limit or math.huge
					return if stock > 0 and equipped ~= nil
						then (if equipped == true then "UNEQUIP" else "EQUIP")
						else (if stock < stockLimit then `${abbreviateNumber(shopData.CashCost)}` else "MAX")
				end)

				return toolName,
					Tool(toolScope, {
						order = shopData.Order,

						toolName = toolName,
						canInteract = canInteract,
						statusText = statusText,

						unlocked = unlocked,
						unlockText = shopData.UnlockText or `{shopData.RebirthsRequired} rebirths required`,

						title = shopData.Title,
						description = shopData.Description,

						image = shopData.Image,

						titleGradient = shopData.TitleGradient,
						descriptionGradient = shopData.DescriptionGradient,

						interact = function()
							local invData: Types.InventoryToolData = peek(props.inventory)[toolName]
							local hasItem = invData.Stock and peek(invData.Stock) > 0
							if shopData.PassId and not hasItem then
								MonitizationClient.PromptPurchase(shopData.PassId)
							else
								props.toolInteractAttempt(toolName)
							end
						end,
					})
			end
		),
	})

	return
end

return ToolShopMenu
