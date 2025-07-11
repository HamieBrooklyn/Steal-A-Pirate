local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LasersModelTemp = ReplicatedStorage.Assets.Models.Lasers

local Services = ReplicatedStorage.Shared.Modules.Services
local SpawningServiceFold = Services.SpawningService

local PlayerDataServer = require(Services.PlayerDataService.Server)
local PlayerServer = require(Services.PlayerService.Server)

local SharedSpawningTypes = require(SpawningServiceFold.Types)
local SharedSpawningData = require(SpawningServiceFold.Data)

local Character = require(SpawningServiceFold.Server.Character)

local SharedTypes = require(script.Parent.Parent.Types)
local SharedData = require(script.Parent.Parent.Data)
local Events = require(script.Parent.Events)

local Platform = require(script.Platform)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local observeDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.observeDescendants)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)
local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)

local scoped, peek = Fusion.scoped, Fusion.peek

local Base = {}
Base.__index = Base

type self = {
	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	Id: string,

	Model: Model,
	Platforms: { [string]: Platform.Platform },
	platformsByIndex: { [number]: Platform.Platform },

	Owner: Fusion.Value<number?, any>,
	player: Fusion.Value<Player?, any>,

	CharactersInBase: Fusion.Value<{ SharedSpawningTypes.CharacterData }, any>,
	CharactersAdding: Fusion.Value<{ Character.Character }, any>,
	BaseFull: Fusion.Value<boolean, any>,

	locked: Fusion.Value<boolean, any>,
	lastLocked: Fusion.Value<number, any>,
}
export type Base = typeof(setmetatable({} :: self, Base))

function Base.new(model: Model): Base
	local self = setmetatable({}, Base) :: Base

	self.Id = HttpService:GenerateGUID(false)
	model:SetAttribute("BaseId", self.Id)

	local scope = scoped(Fusion)
	self._scope = scope

	local owner = scope:Value(nil)
	self.Owner = owner
	self.player = scope:Value(nil)

	self.CharactersInBase = scope:Value({})
	self.CharactersAdding = scope:Value({})
	self.characterCount = scope:Value(0)

	local function checkCharCount()
		local inBaseCount = 0
		for _, _ in peek(self.CharactersInBase) do
			inBaseCount += 1
		end
		self.characterCount:set(inBaseCount + #peek(self.CharactersAdding))
	end
	scope:Observer(self.CharactersInBase):onBind(checkCharCount)
	scope:Observer(self.CharactersAdding):onBind(checkCharCount)

	self.BaseFull = scope:Value(false)
	local function checkFull()
		local player = peek(self.player)
		local total = math.clamp(
			peek(self.characterCount)
				+ (
					(
							player
							and peek(PlayerServer.players[tostring(player.UserId)].Stealing.characterStealingName)
								~= nil
						)
						and 1
					or 0
				),
			0,
			SharedData.MaxCharacterCapacity
		)
		--print(total)
		self.BaseFull:set(total == SharedData.MaxCharacterCapacity)
	end
	scope:Observer(self.CharactersAdding):onBind(checkFull)
	scope:Observer(self.CharactersInBase):onBind(checkFull)

	local trove = Trove.new()
	self._trove = trove

	self.Model = model

	local ownerSignLabel: TextLabel =
		model:FindFirstChild("BaseOwnerSign"):FindFirstChild("Board"):FindFirstChild("Owner")
	scope:Observer(owner):onBind(function()
		local newOwnerId = peek(owner)
		local player = if newOwnerId then Players:GetPlayerByUserId(newOwnerId) else nil
		ownerSignLabel.Text = SharedData.SignString:format(player and player.Name or "No one")

		self.player:set(if player then player else nil)
		if player then
			trove:Add(player.CharacterAdded:Connect(function(char)
				char:PivotTo(model:FindFirstChild("SpawnLocation"):GetPivot())
			end))
		end
	end)

	local playerTrove = Trove.new()
	scope:Observer(self.player):onBind(function()
		playerTrove:Clean()

		local player = peek(self.player)
		if not player then
			return
		end

		local con: RBXScriptConnection?
		con = playerTrove:Add(PlayerServer.PlayerLoaded:Connect(function(playerLoaded: Player)
			if playerLoaded ~= player then
				return
			end
			if con then
				con:Disconnect()
				con = nil
			end
			playerTrove:Add(
				scope
					:Observer(PlayerServer.players[tostring(player.UserId)].Stealing.characterStealingName)
					:onChange(checkFull)
			)
		end))
	end)

	local platformModels = model:FindFirstChild("Platforms"):GetChildren()
	table.sort(platformModels, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	local platforms: { [string]: Platform.Platform } = {}
	local platfomsByIndex: { [number]: Platform.Platform } = {}
	for _, platformModel in platformModels do
		if platformModel:IsA("Model") then
			local platform = Platform.new(platformModel, {
				lastCollected = os.time(),

				baseModel = model,
				owner = owner,
			})

			local function remove()
				local state = table.clone(peek(self.CharactersInBase))
				state[tonumber(platformModel.Name)] = nil
				self.CharactersInBase:set(state)
			end
			platform.trove:Add(platform.stolen:Connect(remove))
			platform.trove:Add(platform.WasReset:Connect(remove))

			platfomsByIndex[tonumber(platform.Model.Name)] = platform
			platforms[platform.Id] = platform
		end
	end
	self.Platforms = platforms
	self.platformsByIndex = platfomsByIndex

	local lastUpdate = time()
	trove:Add(RunService.Heartbeat:Connect(function()
		if time() - lastUpdate >= 1 then
			lastUpdate = time()
			for _, v in platforms do
				if not peek(v.CharacterData) then
					continue
				end
				v:Heartbeat()
			end
		end
	end))

	self.locked = scope:Value(false)
	self.lastLocked = scope:Value(0)

	local lockTrove = Trove.new()
	scope:Observer(self.locked):onChange(function()
		lockTrove:Clean()

		local lockedState = peek(self.locked)

		if not lockedState then
			return
		end

		local lasers = LasersModelTemp:Clone()
		lockTrove:Add(lasers)

		lasers:PivotTo(model:FindFirstChild("Entrance"):GetPivot())
		lasers.Parent = model

		Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.BaseLocked, lasers.PrimaryPart):Play()

		local player = Players:GetPlayerByUserId(peek(self.Owner))
		lockTrove:Add(observeCharacter(player, function(char)
			local con = observeDescendants(char, function(descendant)
				if not descendant:IsA("BasePart") then
					return
				end
				lockTrove:Add(scope:New("NoCollisionConstraint")({
					Part0 = descendant,
					Part1 = lasers.PrimaryPart,
					Parent = descendant,
				}))
			end)
			return function()
				con:Disconnect()
			end
		end))

		self.lastLocked:set(tick())
		lockTrove:Add(RunService.Heartbeat:Connect(function()
			if tick() - peek(self.lastLocked) >= SharedData.LockedDuration then
				self.locked:set(false)
			end
		end))

		Events.BaseLocked:FireAllClients(self.Id, tostring(peek(self.lastLocked)))
	end)

	local toucher = Toucher.new(model:FindFirstChild("Entrance"))
	trove:Add(toucher)
	trove:Add(toucher.PlayerTouched:Connect(function(player: Player)
		if player == peek(self.player) then
			local stealing = PlayerServer.players[tostring(player.UserId)].Stealing
			if peek(stealing.isStealing) and not peek(self.BaseFull) then
				self:AddCharacter(player, peek(stealing.characterStealingName))
				stealing:CancelSteal()
			end
		end
	end))

	return self
end

function Base.AddCharacter(
	self: Base,
	player: Player,
	characterName: string,
	savedData: SharedTypes.SavedPlatformData?,
	loadedIndex: number?
)
	local playerProfile = PlayerDataServer.Profiles[player]

	local characterData = SharedSpawningData.Characters.Info[characterName]

	for i, v in self.platformsByIndex do
		if (loadedIndex and i ~= loadedIndex) or (tonumber(v.Model.Name) ~= i) then
			continue
		end
		if peek(v.CharacterData) == nil then
			if savedData then
				v.LastCollected = savedData.LastCollectedTime
			end

			v.CharacterName:set(characterName)
			v.CharacterData:set(characterData)

			v:LoadGenerated()

			local state = table.clone(peek(self.CharactersInBase))
			state[i] = characterData
			self.CharactersInBase:set(state)

			if not savedData then
				playerProfile.Data.Platforms[i] = {
					LastCollectedTime = os.time(),
					CharacterName = characterName,
				}
			end

			break
		end
	end
end

function Base.AddCharacterAttempt(
	self: Base,
	player: Player,
	characterName: string,
	character: Character.Character,
	ignoreSave: boolean?
)
	local charactersAddingState = peek(self.CharactersAdding)
	local charAddingIndex = table.find(charactersAddingState, character)
	if peek(self.BaseFull) and not charAddingIndex then
		return
	end

	local playerProfile = PlayerDataServer.Profiles[player]
	if not playerProfile then
		warn(player.Name .. "'s profile was not loaded yet")
		return
	end

	charactersAddingState = table.clone(charactersAddingState)
	table.remove(charactersAddingState, charAddingIndex)
	self.CharactersAdding:set(charactersAddingState)

	self:AddCharacter(player, characterName, ignoreSave)
end

function Base.GetPlatformData(self: Base)
	local loadedPlatforms = {}
	for _, v in self.Platforms do
		local charName: string? = peek(v.CharacterName)
		if not charName then
			continue
		end
		table.insert(loadedPlatforms, {
			platformId = v.Id,
			characterName = charName,
			lastCollectedTime = v.LastCollected,
		})
	end
	return loadedPlatforms
end

function Base.Load(self: Base)
	Events.BaseLoaded:FireAllClients({
		baseId = self.Id,
		ownerId = peek(self.Owner),
		lastLockedTime = peek(self.lastLocked),
		platforms = self:GetPlatformData(),
	})
end

function Base.Reset(self: Base)
	self.Owner:set(nil)
	self.locked:set(false)
	self.CharactersAdding:set({})
	self.CharactersInBase:set({})
	for _, v in self.Platforms do
		v:Reset()
	end
end

function Base.Destroy(self: Base): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Base
