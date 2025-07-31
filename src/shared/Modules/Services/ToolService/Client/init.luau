local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedData = require(script.Parent.Data)
local Types = require(script.Types)

local ToolShopMenu = require(script.ToolShopMenu)

local PlayerDataClient = require(Services.PlayerDataService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)
local Trove = require(ReplicatedStorage.Packages.Trove)

local scoped, peek = Fusion.scoped, Fusion.peek

local toolInteractAttempt = Net:RemoteEvent("ToolInteractAttempt")
local getInventory = Net:RemoteFunction("GetInventory")

local player = Players.LocalPlayer

local ToolClient = {
	playerTools = {} :: { [Tool]: { any } },
}

function ToolClient.init()
	ToolClient.toolClasses = {}
	for _, v in script.Tools:GetChildren() do
		ToolClient.toolClasses[v.Name] = require(v)
	end

	observeCharacter(player, function(_char)
		local trove = Trove.new()

		trove:Add(observeChildren(player.Backpack, function(child: Instance)
			local funcName = child:GetAttribute("Functionality")
			local toolClass = ToolClient.toolClasses[child.Name] or (funcName and ToolClient.toolClasses[funcName])
			if not child:IsA("Tool") or not toolClass or ToolClient.playerTools[child] then
				return
			end

			local tool = toolClass.new(child)
			ToolClient.playerTools[child] = tool

			return function()
				if ToolClient.playerTools then
					ToolClient.playerTools[child] = nil
				end
				tool:Destroy()
			end
		end))

		return function()
			trove:Destroy()
		end
	end)

	local scope = scoped(Fusion)

	local inv: { Types.InventoryToolData } = {}
	for i, v in SharedData.ShopTools do
		inv[i] = {
			Stock = scope:Value(0),
			Equipped = if v.GetType == "Equip" then scope:Value(false) else nil,
		}
	end
	ToolClient.inventory = scope:Value(inv) :: Fusion.Value<{ [string]: Types.InventoryToolData }>
	local function updateInventory(updatedInventory: { [string]: {
		Amount: number,
		Equipped: boolean,
	} })
		local invState: { [string]: Types.InventoryToolData } = peek(ToolClient.inventory)
		for i, v in updatedInventory do
			if not invState[i] then
				invState[i] = {
					Stock = scope:Value(v.Amount),
					Equipped = if v.GetType == "Equip" then scope:Value(false) else nil,
				}
			else
				invState[i].Stock:set(v.Amount)
			end
			if invState[i].Equipped ~= nil then
				invState[i].Equipped:set(v.Equipped)
			end
		end
		for i, v in invState do
			if not updatedInventory[i] then
				if v.Equipped ~= nil then
					v.Equipped:set(false)
				end
				v.Stock:set(0)
			end
		end
		pcall(function()
			ToolClient.inventory:set(invState)
		end)
	end
	Net:Connect("InventoryUpdated", updateInventory)

	local function createMenu()
		updateInventory(getInventory:InvokeServer())
		ToolShopMenu(scope, {
			inventory = ToolClient.inventory,
			toolInteractAttempt = function(toolName: string)
				toolInteractAttempt:FireServer(toolName)
			end,
		})
	end
	if not Players.LocalPlayer:GetAttribute("ProfileLoaded") then
		PlayerDataClient.LeaderstatsLoaded:Once(createMenu)
	else
		createMenu()
	end
end

return ToolClient
