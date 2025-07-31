local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Services = ReplicatedStorage.Shared.Modules.Services
local Characters = ReplicatedStorage.Assets.Models.Characters

local PirateInteractPrompt = ReplicatedStorage.Assets.Templates.PirateInteract

local MonitizationServer = require(Services.MonitizationService.Server)
local PlayerDataServer = require(Services.PlayerDataService.Server)
local SettingsServer = require(Services.SettingsService.Server)
local PlayerServer = require(Services.PlayerService.Server)

local SharedSpawningData = require(Services.SpawningService.Data)
local SharedRebirthData = require(Services.RebirthService.Data)

local SharedSpawningTypes = require(ReplicatedStorage.Shared.Modules.Services.SpawningService.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(script.Parent.Parent.Events)
local observeDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.observeDescendants)
local glueCharacterToCurrentPosition =
	require(ReplicatedStorage.Shared.Modules.Utilities.glueCharacterToCurrentPosition)
local getMutationsString = require(ReplicatedStorage.Shared.Modules.Utilities.getMutationsString)

local scoped, peek = Fusion.scoped, Fusion.peek

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local Platform = {}
Platform.__index = Platform

type self = {
	_scope: Fusion.Scope<any>,
	_characterTrove: Trove.Trove,
	trove: Trove.Trove,

	Id: string,
	BaseId: string,

	WasReset: Signal.Signal,
	stolen: Signal.Signal,
	collected: Signal.Signal,

	Model: Model,

	CharacterData: Fusion.Value<SharedSpawningTypes.CharacterData?, any>,
	CharacterName: Fusion.Value<string?, any>,
	Mutations: Fusion.Value<{ string }, any>,
	characterModel: Fusion.Value<Model?, any>,
	characterCFrame: CFrame?,

	LastCollected: number,

	Generated: Fusion.Value<number, any>,
	Owner: Fusion.Value<number?, any>,

	ownerHas2X: Fusion.Value<boolean, any>,
}
export type Platform = typeof(setmetatable({} :: self, Platform))

function Platform.new(
	model: Model,
	props: {
		lastCollected: number,

		startData: SharedSpawningTypes.CharacterData?,
		startName: string?,

		baseModel: Model,
		owner: Fusion.Value<number?, any>,
	}
): Platform
	local self = setmetatable({}, Platform) :: Platform

	self.Id = HttpService:GenerateGUID(false)
	self.BaseId = props.baseModel:GetAttribute("BaseId")
	model:SetAttribute("PlatformId", self.Id)

	local scope = scoped(Fusion)
	self._scope = scope

	self.trove = Trove.new()

	self.WasReset = Signal.new()
	self.stolen = Signal.new()
	self.collected = Signal.new()

	self.Model = model
	self.Owner = props.owner

	local generated = scope:Value(0)
	self.Generated = generated

	self.CharacterData = scope:Value(props.startData)
	self.CharacterName = scope:Value(props.startName)
	self.Mutations = scope:Value({})
	self.isOccupied = scope:Value(peek(self.CharacterData) and peek(self.CharacterName))
	self.characterModel = scope:Value(nil)

	local function checkOccupied()
		self.isOccupied:set(peek(self.CharacterData) and peek(self.CharacterName))
	end
	scope:Observer(self.CharacterName):onBind(checkOccupied)
	scope:Observer(self.CharacterData):onBind(checkOccupied)

	local characterTrove = Trove.new()
	self._characterTrove = characterTrove
	scope:Observer(self.CharacterData):onBind(function()
		characterTrove:Clean()

		local name = peek(self.CharacterName)

		local state = peek(self.CharacterData)
		if not state then
			return
		else
			self.LastCollected = self.LastCollected or os.time()
			local mutations = peek(self.Mutations)
			Events.PlatformCharactersSetQueue:Add({
				baseId = self.BaseId,
				platformId = self.Id,

				characterName = name,
				lastCollectedTime = self.LastCollected,
				mutations = if #mutations > 0 then mutations else nil,
			})
		end

		local charModel: Model = Characters:FindFirstChild(name):Clone()
		for _, v: BasePart? in charModel:GetDescendants() do
			if v:IsA("BasePart") then
				v.AssemblyLinearVelocity = Vector3.zero
			end
		end
		characterTrove:Add(charModel)
		characterTrove:Add(observeDescendants(charModel, function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = "Pirate"
			end
		end))
		charModel:SetAttribute("PirateName", name)
		charModel:AddTag("PirateInfo")

		local hum = charModel:FindFirstChildOfClass("Humanoid")
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)

		local mutationsState = peek(self.Mutations)
		if #mutationsState > 0 then
			local mString = getMutationsString(mutationsState)
			charModel:SetAttribute("Mutations", mString)
			charModel:AddTag("Mutated")
		end

		ReplicatedStorage.Assets.Templates.Animate:Clone().Parent = charModel
		charModel:PivotTo(
			model:FindFirstChild("Placement"):GetPivot() * CFrame.new(0, charModel:GetExtentsSize().Y / 2, 0)
		)
		charModel.Parent = model

		task.delay(0.05, function()
			local landCon: RBXScriptConnection
			landCon = characterTrove:Add(RunService.Heartbeat:Connect(function()
				if hum.FloorMaterial ~= Enum.Material.Air then
					self.characterCFrame = charModel:GetPivot()
					self.trove:Add(glueCharacterToCurrentPosition(charModel))
					landCon:Disconnect()
				end
			end))
		end)

		self.characterModel:set(charModel)
	end)

	return self
end

function Platform.GetMultiplier(self: Platform): number
	local mult = 0
	local ownerUserId = peek(self.Owner)
	if
		ownerUserId
		and MonitizationServer.playerGamepasses[ownerUserId]
		and MonitizationServer.playerGamepasses[ownerUserId]["2XMoney"] == true
	then
		mult += 2
	end

	for _, v in peek(self.Mutations) do
		mult += SharedSpawningData.Mutations[v].Mult
	end

	local playerProfile = PlayerDataServer.GetPlayerProfile(Players:GetPlayerByUserId(peek(self.Owner)))

	mult += peek(SharedRebirthData.Constants.CashMultiplier * peek(playerProfile.Data.Leaderstats.Rebirths))

	if mult < 1 then
		mult += 1
	end

	return mult
end

function Platform.LoadGenerated(self: Platform)
	local generated =
		math.floor((os.time() - self.LastCollected) * (peek(self.CharacterData).Cashflow * self:GetMultiplier()))
	self.Generated:set(generated)
end

function Platform.Heartbeat(self: Platform)
	local data: SharedSpawningTypes.CharacterData = peek(self.CharacterData)
	if data then
		local mult = self:GetMultiplier()
		local ownerUserId = peek(self.Owner)
		local playerData = PlayerServer.players[tostring(ownerUserId)]
		if playerData and (playerData.FriendBoostMult() - 1) > 0 then
			mult += (playerData.FriendBoostMult() - 1)
		end
		-- print(mult)

		local generated = math.floor(peek(self.Generated) + (data.Cashflow * mult))
		if
			ownerUserId
			and SettingsServer.playerSettings[ownerUserId]
			and SettingsServer.playerSettings[ownerUserId]["AutoCollect"]
		then
			if peek(self.Generated) > 0 then
				self:Collect()
			else
				self:GivePlayerEarnings(generated)
			end
		else
			self.Generated:set(generated)
		end

		local charModelState: Model? = peek(self.characterModel)
		if charModelState and self.characterCFrame then
			charModelState:PivotTo(self.characterCFrame)
		end
	end
end

function Platform.GivePlayerEarnings(self: Platform, generated: number)
	local player = Players:GetPlayerByUserId(peek(self.Owner))
	if not player then
		return
	end
	local profile = PlayerDataServer.Profiles[player]
	if not profile then
		warn(player.Name .. "'s profile hasnt loaded yet")
		return
	end
	local earnings = math.floor(generated * math.max(self:GetMultiplier(), 1))
	PlayerDataServer.UpdateLeaderstat(player, "Cash", earnings)
	PlayerDataServer.GetPlayerProfileData(player).TotalEarnings += earnings
end

function Platform.Collect(self: Platform)
	local player = Players:GetPlayerByUserId(peek(self.Owner))
	if not player then
		return
	end
	local profile = PlayerDataServer.Profiles[player]
	if not profile then
		warn(player.Name .. "'s profile hasnt loaded yet")
		return
	end

	local lastCollected = os.time()

	if profile.Data.Platforms[tonumber(self.Model.Name)] then
		profile.Data.Platforms[tonumber(self.Model.Name)].LastCollectedTime = lastCollected
	end

	self.LastCollected = lastCollected
	self:GivePlayerEarnings(peek(self.Generated))

	pcall(function()
		self.Generated:set(0)
	end)
	self.collected:Fire()

	self:Heartbeat()

	Events.PlatformCollected:FireAllClients(self.BaseId, self.Id)
end

local function characterInteractIsValid(self: Platform, char: Model): boolean
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health < 1 then
		return false
	end
	local characterModel: Model = peek(self.characterModel)
	if not characterModel then
		return false
	end

	params.FilterDescendantsInstances = { char:GetDescendants() }

	local origin = char:GetPivot().Position
	local dir = characterModel:GetPivot().Position - origin
	local result: RaycastResult? =
		workspace:Raycast(origin, dir * (PirateInteractPrompt.MaxActivationDistance * 15), params)

	if not result or not result.Instance or not result.Instance:IsDescendantOf(characterModel) then
		return false
	end

	return true
end

function Platform:GetUserProfile()
	local player = Players:GetPlayerByUserId(peek(self.Owner))
	if not player then
		return
	end
	local profile = PlayerDataServer.GetPlayerProfile(player)
	return player, profile
end

function Platform.Sell(self: Platform)
	local player, profile = self:GetUserProfile()
	if not player or not profile then
		return
	end

	local index = tonumber(self.Model.Name)
	assert(profile.Data.Platforms[index] ~= nil, player.Name .. " had no data for platform index: " .. index)

	if not characterInteractIsValid(self, player.Character) then
		return
	end

	local earnings = math.floor(peek(self.CharacterData).Price / 2)
	PlayerDataServer.UpdateLeaderstat(player, "Cash", earnings)
	PlayerDataServer.GetPlayerProfileData(player).TotalEarnings += earnings

	self:Collect()
	self:Reset(false)

	profile.Data.Platforms[index] = nil

	Events.PlatformSold:FireAllClients(self.BaseId, self.Id)
end

function Platform.Steal(self: Platform, playerStealing: Player)
	if not characterInteractIsValid(self, playerStealing.Character) then
		return
	end

	local player = Players:GetPlayerByUserId(peek(self.Owner))
	if not player then
		return
	end
	local profile = PlayerDataServer.Profiles[player]
	if not profile then
		warn(player.Name .. "'s profile hasnt loaded yet")
		return
	end

	local stealing = PlayerServer.players[tostring(playerStealing.UserId)].Stealing
	assert(not peek(stealing.isStealing), playerStealing.Name .. " is already stealing a character")

	profile.Data.Platforms[tonumber(self.Model.Name)] = nil
	self.stolen:Fire()

	stealing:StealCharacter(player, peek(self.CharacterName), peek(self.Mutations))

	self.CharacterData:set(nil)
	self.CharacterName:set(nil)
	self._characterTrove:Clean()

	Events.CharacterStolen:FireAllClients(self.BaseId, self.Id, playerStealing)
end

function Platform.Reset(self: Platform, removeFromSave: boolean)
	if removeFromSave then
		local player, profile = self:GetUserProfile()
		if not player or not profile then
			return
		end
		local index = tonumber(self.Model.Name)
		profile.Data.Platforms[index] = nil
	end

	self.WasReset:Fire()

	Events.platformsResetTask:Add({
		baseId = self.BaseId,
		platformId = self.Id,
	})

	self.Generated:set(0)
	self.LastCollected = nil
	self.CharacterData:set(nil)
	self.CharacterName:set(nil)
	self.Mutations:set({})
	self._characterTrove:Clean()
end

function Platform.Destroy(self: Platform): ()
	self._scope:doCleanup()
end

return Platform
