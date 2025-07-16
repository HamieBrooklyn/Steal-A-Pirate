local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services
local Characters = ReplicatedStorage.Assets.Models.Characters

local PirateInteractPrompt = ReplicatedStorage.Assets.Templates.PirateInteract

local MonitizationServer = require(Services.MonitizationService.Server)
local PlayerDataServer = require(Services.PlayerDataService.Server)
local SharedRebirthData = require(Services.RebirthService.Data)
local SettingsServer = require(Services.SettingsService.Server)
local PlayerServer = require(Services.PlayerService.Server)

local SharedSpawningTypes = require(ReplicatedStorage.Shared.Modules.Services.SpawningService.Types)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(script.Parent.Parent.Events)
local observeDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.observeDescendants)

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

	Model: Model,

	CharacterData: Fusion.Value<SharedSpawningTypes.CharacterData?, any>,
	CharacterName: Fusion.Value<string?, any>,
	characterModel: Fusion.Value<Model?, any>,

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

	self.Model = model
	self.Owner = props.owner

	local generated = scope:Value(0)
	self.Generated = generated

	self.CharacterData = scope:Value(props.startData)
	self.CharacterName = scope:Value(props.startName)
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

		local state = peek(self.CharacterData)
		if not state then
			return
		else
			self.LastCollected = self.LastCollected or os.time()
			Events.PlatformCharactersSetQueue:Add({
				baseId = self.BaseId,
				platformId = self.Id,

				characterName = peek(self.CharacterName),
				lastCollectedTime = self.LastCollected,
			})
		end

		local charModel: Model = Characters:FindFirstChild(peek(self.CharacterName)):Clone()
		characterTrove:Add(charModel)
		characterTrove:Add(observeDescendants(charModel, function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = "Pirate"
			end
		end))

		charModel:PivotTo(model:FindFirstChild("Placement"):GetPivot() * CFrame.new(0, 5, 0))
		charModel.Parent = model
		self.characterModel:set(model)
	end)

	return self
end

function Platform.LoadGenerated(self: Platform)
	local generated = math.floor((os.time() - self.LastCollected) * peek(self.CharacterData).Cashflow)
	self.Generated:set(generated)
end

function Platform.Heartbeat(self: Platform)
	local data: SharedSpawningTypes.CharacterData = peek(self.CharacterData)
	if data then
		local mult = 0
		local ownerUserId = peek(self.Owner)
		if
			ownerUserId
			and MonitizationServer.playerGamepasses[ownerUserId]
			and MonitizationServer.playerGamepasses[ownerUserId]["2XCash"] == true
		then
			mult += 2
		end

		local generated = math.floor(peek(self.Generated) + (data.Cashflow * math.max(mult, 1)))
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
	local earnings = math.floor(
		generated * math.max((SharedRebirthData.Constants.CashMultiplier * profile.Data.Leaderstats.Rebirths), 1)
	)
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
	local result: RaycastResult? = workspace:Raycast(origin, dir * PirateInteractPrompt.MaxActivationDistance, params)

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

	local earnings = peek(self.CharacterData).Price
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

	stealing:StealCharacter(player, peek(self.CharacterName))

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

	local charName = peek(self.CharacterName)
	if charName then
		Events.platformsResetTask:Add({
			baseId = self.BaseId,
			platformId = self.Id,
		})
	end

	self.Generated:set(0)
	self.LastCollected = nil
	self.CharacterData:set(nil)
	self.CharacterName:set(nil)
	self._characterTrove:Clean()
end

function Platform.Destroy(self: Platform): ()
	self._scope:doCleanup()
end

return Platform
