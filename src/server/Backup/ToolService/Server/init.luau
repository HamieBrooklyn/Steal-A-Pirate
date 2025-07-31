local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services

local Tools = script.Tools

local PlayerDataServer = require(Services.PlayerDataService.Server)
local BaseServer = require(Services.BaseService.Server)

local SharedData = require(script.Parent.Data)

local observeChildren = require(Modules.Utilities.observeChildren)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)

local peek = Fusion.peek

local ToolServer = {
	sharedData = SharedData,

	playerTools = {} :: { [Tool]: { any } },
}

function ToolServer.GivePlayerTool(
	player: Player,
	toolName: string,
	amount: number?,
	saveOnDeath: boolean?,
	saveOnLeave: boolean?
)
	amount = amount or 1
	local tool = ReplicatedStorage.Assets.Tools:FindFirstChild(toolName)

	if not player.Character then
		player.CharacterAdded:Wait()
	end

	for _ = 1, amount do
		tool:Clone().Parent = player.Backpack
		if saveOnDeath then
			tool:Clone().Parent = player.StarterGear
		end
	end
	if saveOnLeave then
		ToolServer.SaveToolToPlayer(player, toolName, amount)
	end
end

function ToolServer.SaveToolToPlayer(player: Player, toolName: string, saveOnDeath: boolean?, amount: number?)
	amount = amount or 1

	local profileData = PlayerDataServer.GetPlayerProfileData(player)
	if not profileData then
		return
	end

	if profileData.Tools[toolName] then
		profileData.Tools[toolName].Amount += 1
	else
		profileData.Tools[toolName] = {
			Amount = amount,
			SaveOnDeath = saveOnDeath,
		}
	end
end

function ToolServer.RemoveToolFromPlayer(player: Player, tool: Tool, dontRemoveFromSave: boolean)
	local profile = PlayerDataServer.GetPlayerProfile(player)
	if not profile then
		return
	end
	if not tool or not tool.Parent then
		return
	end

	local starterTool = player.StarterGear:FindFirstChild(tool.Name)
	if starterTool then
		starterTool:Destroy()
	end

	local toolName = tool.Name
	if not dontRemoveFromSave then
		if profile.Data.Tools[toolName] then
			profile.Data.Tools[toolName].Amount -= 1
			if profile.Data.Tools[toolName].Amount < 1 then
				profile.Data.Tools[toolName] = nil
			end
		end
	end

	ToolServer.playerTools[player.UserId][tool] = nil
	tool:Destroy()
end

function ToolServer.PlayerOwnsTool(player: Player, toolName: string): (boolean, number)
	local count = 0
	local found = false
	for i, _ in ToolServer.playerTools[player.UserId] do
		if i.Name == toolName then
			count += 1
			found = true
		end
	end
	return found, count
end

function ToolServer.GetPlayerToolFromUpgradeCategory(player: Player, category: string): Tool?
	local function search(parent: Instance)
		for _, v in parent:GetChildren() do
			if v:IsA("Tool") and v:GetAttribute("UpgradeCategory") == category then
				return v
			end
		end
	end
	for _, v in { player.Backpack, player.Character, player.StarterGear } do
		local tool = search(v)
		if tool then
			return tool
		end
	end
end

function ToolServer.init()
	local toolClasses = {}
	for _, v in Tools:GetChildren() do
		if v:IsA("ModuleScript") then
			toolClasses[v.Name] = require(v)
		end
	end

	ToolServer.floorItemClasses = {}
	for _, v in script.Classes.FloorItems:GetChildren() do
		if v:IsA("ModuleScript") then
			ToolServer.floorItemClasses[v.Name] = require(v)
		end
	end

	Observers.observeCharacter(function(player)
		local trove = Trove.new()

		ToolServer.playerTools[player.UserId] = {}

		trove:Add(observeChildren(player.Backpack, function(child: Instance)
			local funcName = child:GetAttribute("Functionality")
			local toolClass = (funcName and toolClasses[funcName]) or toolClasses[child.Name]

			if not child:IsA("Tool") or not toolClass or ToolServer.playerTools[player.UserId][child] then
				return
			end

			local tool = toolClass.new(player, child, function()
				ToolServer.RemoveToolFromPlayer(player, child)
			end)
			ToolServer.playerTools[player.UserId][child] = tool

			return function()
				ToolServer.RemoveToolFromPlayer(player, tool)
			end
		end))

		return function()
			ToolServer.playerTools[player.UserId] = nil
			trove:Destroy()
		end
	end)

	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		for i, v in PlayerDataServer.Profiles[player].Data.Tools do
			ToolServer.GivePlayerTool(player, i, v.Amount, v.SaveOnDeath, false)
		end
		if not ToolServer.GetPlayerToolFromUpgradeCategory(player, "Slap") then
			ToolServer.GivePlayerTool(player, SharedData.StarterTool, 1, true, false)
		end
	end)

	Net:Connect("BuyToolAttempt", function(player: Player, toolName: string)
		assert(toolName and typeof(toolName) == "string", "The sent tool name was not of type string")

		local toolData = SharedData.ShopTools[toolName]
		assert(toolData, toolName .. " was not found as a tool shop item data")

		local tool = ReplicatedStorage.Assets.Tools:FindFirstChild(toolName)
		assert(tool, toolName .. " did not exist in ReplicatedStorage/Assets/Tools")

		local profileData = PlayerDataServer.GetPlayerProfileData(player)
		if not profileData then
			return
		end
		assert(
			profileData.Leaderstats.Rebirths >= toolData.RebirthsRequired,
			player.Name .. " did not have enough rebirths to buy sent tool"
		)
		assert(
			profileData.Leaderstats.Cash >= toolData.CashCost,
			player.Name .. " did not have enough cash to buy " .. tool.Name
		)
		PlayerDataServer.UpdateLeaderstat(player, "Cash", -math.floor(toolData.CashCost))

		assert(
			not profileData.Tools[toolName] or profileData.Tools[toolName].Amount < toolData.Limit,
			player.Name .. " had reached the limit of sent item in their inventory"
		)

		local upgradeCategory = tool:GetAttribute("UpgradeCategory")
		if upgradeCategory then
			local prevTool = ToolServer.GetPlayerToolFromUpgradeCategory(player, upgradeCategory)
			if prevTool then
				ToolServer.RemoveToolFromPlayer(player, prevTool)
			end
		end
		ToolServer.GivePlayerTool(player, toolName, 1, true, true)
	end)

	Net:Connect("PlaceFloorItem", function(player: Player, tool: Tool, position: Vector3)
		assert(
			tool and typeof(tool) == "Instance" and tool:IsA("Tool") and ToolServer.floorItemClasses[tool.Name],
			"Invalid tool"
		)
		assert(position and typeof(position) == "Vector3", "Sent position was not of type Vector3")

		local profile = PlayerDataServer.GetPlayerProfile(player)
		if not profile then
			return
		end

		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health < 1 then
			return
		end

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { char }

		local origin = char:GetPivot().Position
		if (origin - position).Magnitude > 20 then
			return
		end
		local result: RaycastResult? = workspace:Raycast(origin, (position - origin) * 20, params)
		if result and result.Position and (result.Position - position).Magnitude < 1 then
			ToolServer.RemoveToolFromPlayer(player, tool)
			ToolServer.floorItemClasses[tool.Name].new(player, result.Position)
		end
	end)
	Net:Handle("UseFruitAttempt", function(player, fruitTool: Tool, data: { any })
		assert(
			fruitTool and typeof(fruitTool) == "Instance" and fruitTool:IsA("Tool"),
			"Sent fruit type was not a Tool"
		)
		assert(data and typeof(data) == "table", "Sent fruit data was not of type table")

		if fruitTool.Name == "Unlock" then
			local baseId = data.baseId
			assert(baseId and typeof(baseId) == "string", "Sent base id was not of type string")

			local base = BaseServer.GetPlayerBase(player)
			if not base then
				return false
			end
			if not peek(base.locked) then
				return false
			end

			assert(ToolServer.PlayerOwnsTool(player, "Unlock Unlock Fruit"), `{player.Name} did not own a unlock fruit`)
			ToolServer.RemoveToolFromPlayer(player, fruitTool)

			base:SetLocked(false)

			return true
		end
	end)
end

return ToolServer
