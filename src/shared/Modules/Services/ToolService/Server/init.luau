local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Services = ReplicatedStorage.Shared.Modules.Services
local SFX = ReplicatedStorage.Assets.Sounds.SoundEffects
local Tools = ReplicatedStorage.Assets.Tools

local SharedData = require(script.Parent.Data)

local MonitizationServer = require(Services.MonitizationService.Server)
local PlayerDataServer = require(Services.PlayerDataService.Server)
local PopupServer = require(Services.PopupService.Server)
local BaseServer = require(Services.BaseService.Server)

local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local updatePlayerInventory = Net:RemoteEvent("InventoryUpdated")

local peek = Fusion.peek

local ToolServer = {}

function ToolServer.GetPlayerToolFromName(player: Player, toolName: string): Tool?
	local function search(parent: Instance)
		for _, v in parent:GetChildren() do
			if v:IsA("Tool") and v.Name == toolName then
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

function ToolServer.GetPlayerToolFromUpgradeCategory(player: Player, category: string): Tool?
	for _, v in SharedData.UpgradeableTools[category] do
		for i, _ in ToolServer.players[player.UserId].equippedTools do
			if i.Name == v.ToolName then
				return i
			end
		end
	end
end

function ToolServer.GivePlayerTool(player: Player, toolName: string, equip: boolean, save: boolean)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end

	if save then
		if playerProfile.Data.Tools[toolName] then
			playerProfile.Data.Tools[toolName].Amount += 1
		else
			playerProfile.Data.Tools[toolName] = {
				Amount = 1,
				Equipped = equip,
			}
		end
	end

	if equip then
		ToolServer.EquipPlayerTool(player, toolName, save)
	end
end

function ToolServer.RemoveToolFromPlayer(player: Player, tool: Tool, save: boolean)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end

	if save then
		if playerProfile.Data.Tools[tool.Name] then
			playerProfile.Data.Tools[tool.Name].Amount -= 1
			if playerProfile.Data.Tools[tool.Name].Amount < 1 then
				playerProfile.Data.Tools[tool.Name] = nil
			end
		end
	end
	tool:Destroy()

	updatePlayerInventory:FireClient(player, playerProfile.Data.Tools)
end

function ToolServer.EquipPlayerTool(player: Player, toolName: string, save: boolean)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end

	local function give()
		local tool = Tools:FindFirstChild(toolName)
		if tool then
			local newTool = tool:Clone()
			newTool.Parent = player.Backpack

			local funcName = tool:GetAttribute("Functionality")
			local toolClass = (funcName and ToolServer.toolClasses[funcName]) or ToolServer.toolClasses[tool.Name]

			if toolClass then
				local newToolClass = toolClass.new(player, newTool, function()
					print(3)
					ToolServer.RemoveToolFromPlayer(player, newTool, true)
				end)
				ToolServer.players[player.UserId].equippedTools[newTool] = newToolClass
			end
		end
		--print(ToolServer.players[player.UserId].equippedTools)
	end

	local toolShopData = SharedData.ShopTools[toolName]
	if toolShopData.GetType == "Stock" then
		give()
	elseif toolShopData.GetType == "Equip" then
		local existingTool = ToolServer.GetPlayerToolFromName(player, toolName)
		if existingTool then
			ToolServer.UnequipPlayerTool(player, existingTool, true)
		elseif not existingTool then
			if toolShopData.Upgrades then
				local tool = ToolServer.GetPlayerToolFromUpgradeCategory(player, toolShopData.Upgrades)
				if tool then
					ToolServer.UnequipPlayerTool(player, tool, true)
					ToolServer.players[player.UserId].equippedTools[tool] = nil
				end
			end

			if save then
				playerProfile.Data.Tools[toolName].Equipped = true
			end
			give()
		end
	end

	updatePlayerInventory:FireClient(player, playerProfile.Data.Tools)
end

function ToolServer.UnequipPlayerTool(player: Player, tool: Tool, save: boolean)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end
	if save then
		if playerProfile.Data.Tools[tool.Name] then
			playerProfile.Data.Tools[tool.Name].Equipped = false
		end
	end
	tool:Destroy()
end

function ToolServer.LoadPlayerTools(player: Player)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end

	for i, v in playerProfile.Data.Tools do
		for _ = 1, v.Amount do
			ToolServer.GivePlayerTool(player, i, true, false)
		end
	end
end

function ToolServer.PlayerOwnsTool(player: Player, toolName: string): (boolean, number?)
	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end

	if playerProfile.Data.Tools[toolName] then
		return true, playerProfile.Data.Tools[toolName].Amount
	end

	return false
end

function ToolServer.init()
	ToolServer.toolClasses = {}
	for _, v in script.Tools:GetChildren() do
		ToolServer.toolClasses[v.Name] = require(v)
	end
	ToolServer.floorItemClasses = {}
	for _, v in script.Classes.FloorItems:GetChildren() do
		if v:IsA("ModuleScript") then
			ToolServer.floorItemClasses[v.Name] = require(v)
		end
	end

	ToolServer.players = {}

	local floorItemsPlaced = {}

	local function checkGamepassTools(player: Player)
		if not player:GetAttribute("ProfileLoaded") or not player:GetAttribute("GamepassesLoaded") then
			return
		end

		for i, v in SharedData.ShopTools do
			if v.PassId then
				local key = MonitizationServer.productKeysById[v.PassId]
				if key then
					if
						not ToolServer.PlayerOwnsTool(player, i)
						and MonitizationServer.playerGamepasses[player.UserId][key]
					then
						ToolServer.GivePlayerTool(player, i, true, true)
					end
				end
			end
		end
	end

	MonitizationServer.playerGamepassesLoaded:Connect(checkGamepassTools)
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		if player.Character:GetAttribute("ToolsLoaded") then
			return
		end
		player.Character:SetAttribute("ToolsLoaded", true)
		-- print("Here")
		ToolServer.LoadPlayerTools(player)
		checkGamepassTools(player)

		local data = PlayerDataServer.GetPlayerProfile(player).Data.Tools[SharedData.StarterTool]
		if not data or not data.Amount or data.Amount < 1 then
			ToolServer.GivePlayerTool(player, SharedData.StarterTool, true, true)
		end
	end)
	Observers.observePlayer(function(player)
		floorItemsPlaced[player.UserId] = {}
		ToolServer.players[player.UserId] = {
			equippedTools = {},
		}

		return function()
			for _, v in floorItemsPlaced[player.UserId] do
				v:Destroy()
			end
			ToolServer.players[player.UserId] = nil
			floorItemsPlaced[player.UserId] = nil
		end
	end)
	Observers.observeCharacter(function(player, character)
		if PlayerDataServer.Profiles[player] and not character:GetAttribute("ToolsLoaded") then
			character:SetAttribute("ToolsLoaded", true)
			ToolServer.LoadPlayerTools(player)
		end
	end)

	Net:Handle("GetInventory", function(player)
		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if playerProfile then
			return playerProfile.Data.Tools
		end
	end)
	Net:Connect("ToolInteractAttempt", function(player: Player, toolName: string)
		assert(toolName and typeof(toolName) == "string", "Sent tool name was not of type string")

		local playerProfile = PlayerDataServer.GetPlayerProfile(player)
		if not playerProfile then
			return
		end

		local toolShopData = SharedData.ShopTools[toolName]
		local function purchaseAttempt()
			assert(
				playerProfile.Data.Leaderstats.Rebirths >= toolShopData.RebirthsRequired,
				`{player.Name} did not have enough rebirths to buy: {toolName}`
			)
			assert(
				playerProfile.Data.Leaderstats.Cash >= toolShopData.CashCost,
				`{player.Name} did not have enough cash to buy: {toolName}`
			)
			PlayerDataServer.UpdateLeaderstat(player, "Cash", -toolShopData.CashCost)

			local invToolData = playerProfile.Data.Tools[toolName]
			assert(
				invToolData == nil or invToolData.Amount < (toolShopData.Limit or math.huge),
				`{player.Name} has too many of: {toolName}`
			)

			ToolServer.GivePlayerTool(player, toolName, true, true)
		end
		if toolShopData then
			if toolShopData.GetType == "Stock" then
				purchaseAttempt()
			elseif toolShopData.GetType == "Equip" then
				if playerProfile.Data.Tools[toolName] then
					ToolServer.EquipPlayerTool(player, toolName, true)
				else
					purchaseAttempt()
				end
			end
		end
	end)

	Net:Connect("PlaceFloorItem", function(player: Player, tool: Tool, position: Vector3)
		assert(
			tool and typeof(tool) == "Instance" and tool:IsA("Tool") and ToolServer.floorItemClasses[tool.Name],
			"Invalid tool"
		)
		assert(position and typeof(position) == "Vector3", "Sent position was not of type Vector3")

		local count = 0
		for _, v in floorItemsPlaced[player.UserId] do
			if v.model.Name == tool.Name then
				count += 1
			end
		end
		if count >= SharedData.MaxOfOneFloorItem then
			PopupServer.SendPopupTo(player, {
				message = `You can only place {SharedData.MaxOfOneFloorItem} {tool.Name}s!`,
				gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.RedApple,
			})
			return
		end

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
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Baseplate }

		local origin = rayGun:FindFirstChild("Handle").Position
		if (origin - position).Magnitude > 20 then
			return
		end
		local result: RaycastResult? = workspace:Raycast(origin, (position - origin) * 20, params)
		if result and result.Position and (result.Position - position).Magnitude < 1 then
			local toolName = tool.Name
			ToolServer.RemoveToolFromPlayer(player, tool, true)

			local floorItem
			floorItem = ToolServer.floorItemClasses[toolName].new(player, result.Position, function()
				table.remove(floorItemsPlaced[player.UserId], table.find(floorItemsPlaced[player.UserId], floorItem))
				print(floorItemsPlaced[player.UserId])
			end)
			table.insert(floorItemsPlaced[player.UserId], floorItem)
		end
		print(floorItemsPlaced[player.UserId])
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

			local playerProfile = PlayerDataServer.GetPlayerProfile(player)
			if not playerProfile then
				return
			end

			assert(playerProfile.Data.Tools["Unlock Unlock Fruit"], `{player.Name} did not own a unlock fruit`)
			ToolServer.RemoveToolFromPlayer(player, fruitTool, true)

			base:SetLocked(false)

			return true
		end
	end)

	local playersRaygunCooldowns = {}
	Net:Connect("FireRayGunAttempt", function(player: Player, rayGun: Tool, mousePosition: Vector3)
		assert(
			rayGun ~= nil
				and typeof(rayGun) == "Instance"
				and rayGun:IsA("Tool")
				and rayGun:GetAttribute("Functionality") == "RayGun",
			`The sent value was not a valid ray gun tool`
		)
		assert(mousePosition ~= nil and typeof(mousePosition) == "Vector3", `Sent mouse position was not a vector 3`)
		if table.find(playersRaygunCooldowns, player) then
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
		if (rayGun:FindFirstChild("Handle").Position - mousePosition).Magnitude > 100 then
			return
		end
		table.insert(playersRaygunCooldowns, player)
		task.delay(2, function()
			local i = table.find(playersRaygunCooldowns, player)
			if i then
				table.remove(playersRaygunCooldowns, i)
			end
		end)

		Sound.new(SFX.FreezeShoot, rayGun:FindFirstChild("Handle")):Play()

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { char }

		local origin = rayGun:FindFirstChild("Handle").Position
		local dest = mousePosition
		local limitedDir = (dest - origin).Unit * 200

		local result: RaycastResult? = workspace:Spherecast(origin, 2, limitedDir, params)
		if result then
			local visual = Instance.new("Part")
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
			visual.Color = Color3.new(0, 0.984313, 1)
			visual.Material = Enum.Material.Glass
			visual.Transparency = 0.5
			visual.Parent = workspace

			local distance = (result.Position - origin).Magnitude
			visual.Size = Vector3.new(0.1, 0.1, distance)
			visual.CFrame = CFrame.lookAt(origin, result.Position) * CFrame.new(0, 0, -distance / 2)
			Debris:AddItem(visual, 0.2)

			local targetChar: Model? = result.Instance.Parent
			if not targetChar:IsA("Model") or targetChar:GetAttribute("Frozen") then
				return
			end
			local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
			if not targetHum or targetHum.Health < 1 then
				return
			end
			if not Players:GetPlayerFromCharacter(targetChar) then
				return
			end

			local trove = Trove.new()

			targetHum:ChangeState(Enum.HumanoidStateType.Physics)
			targetHum.AutoRotate = false
			targetHum.WalkSpeed = 0
			targetHum.JumpHeight = 0
			--targetHum.EvaluateStateMachine = false
			trove:Add(function()
				--targetHum.EvaluateStateMachine = true
				targetHum.WalkSpeed = StarterPlayer.CharacterWalkSpeed
				targetHum.JumpHeight = StarterPlayer.CharacterJumpHeight
				targetHum.AutoRotate = true
			end)
			targetChar:SetAttribute("Frozen", true)
			trove:Add(function()
				targetChar:SetAttribute("Frozen", false)
			end)

			for _, motor: Motor6D? in ipairs(targetChar:GetDescendants()) do
				if motor:IsA("Motor6D") and motor.Name ~= "RootJoint" then
					if motor:FindFirstAncestorOfClass("Tool") then
						continue
					end
					if motor.Part0 and motor.Part0:FindFirstAncestorOfClass("Tool") then
						continue
					end
					if motor.Part1 and motor.Part1:FindFirstAncestorOfClass("Tool") then
						continue
					end

					local da = motor.DesiredAngle
					local mv = motor.MaxVelocity
					motor.DesiredAngle = 0
					motor.MaxVelocity = 0
					trove:Add(function()
						motor.DesiredAngle = da
						motor.MaxVelocity = mv
					end)
				end
			end
			for _, part: BasePart? in ipairs(targetChar:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					local icyClone = part:Clone()
					trove:Add(icyClone)
					icyClone.Material = Enum.Material.Glass
					icyClone.Transparency = 0.75
					icyClone.Color = Color3.fromRGB(131, 255, 234)
					-- icyClone.CanCollide = false
					-- icyClone.CanQuery = false
					-- icyClone.CanTouch = false
					icyClone.Anchored = false
					icyClone.Massless = true
					icyClone.Size *= 1.25
					icyClone.Parent = part
					icyClone:ClearAllChildren()

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = icyClone
					weld.Part1 = part
					weld.Parent = icyClone

					local weld2 = Instance.new("WeldConstraint")
					trove:Add(weld2)
					weld2.Part0 = targetChar.PrimaryPart
					weld2.Part1 = part
					weld2.Parent = part
				end
			end

			Sound.new(SFX.Freeze, targetChar.PrimaryPart):Play()

			task.delay(6, function()
				trove:Destroy()
			end)
		end
	end)
end

return ToolServer
