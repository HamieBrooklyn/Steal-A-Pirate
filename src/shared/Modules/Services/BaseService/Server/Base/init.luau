local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local LasersModelTemp = ReplicatedStorage.Assets.Models.Lasers
local BaseUnlockPrompt = ReplicatedStorage.Assets.Templates.BaseUnlock

local Services = ReplicatedStorage.Shared.Modules.Services
local SpawningServiceFold = Services.SpawningService

local PlayerDataServer = require(Services.PlayerDataService.Server)
local SharedRebirthData = require(Services.RebirthService.Data)
local PlayerServer = require(Services.PlayerService.Server)
local IndexServer = require(Services.IndexService.Server)

local SharedSpawningTypes = require(SpawningServiceFold.Types)
local SharedSpawningData = require(SpawningServiceFold.Data)

local Character = require(SpawningServiceFold.Server.Character)

local SharedTypes = require(script.Parent.Parent.Types)
local SharedData = require(script.Parent.Parent.Data)
local Events = require(script.Parent.Events)

local Platform = require(script.Platform)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local observeDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.observeDescendants)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)
local VolumeWatcher = require(ReplicatedStorage.Shared.Modules.Classes.VolumeWatcher)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)
local Charm = require(ReplicatedStorage.Packages.Charm)

local Observer = Fusion.Observer
local scoped, peek = Fusion.scoped, Fusion.peek

local atom, subscribe = Charm.atom, Charm.subscribe

local baseFull = Net:RemoteEvent("BaseIsFull")

local Base = {
	Platorm = Platform,
}
Base.__index = Base

type self = {
	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	Id: string,

	Model: Model,
	Platforms: { [string]: Platform.Platform },
	platformsByIndex: { [number]: Platform.Platform },
	platformsBeingStolen: Fusion.Value<number>,

	unlockPrompt: ProximityPrompt,

	Owner: Fusion.Value<number?, any>,
	player: Fusion.Value<Player?, any>,

	pirateOnDisplay: Charm.Atom<string?>,
	displayModel: Model?,

	CharactersInBase: Fusion.Value<{ SharedSpawningTypes.CharacterData }, any>,
	CharactersAdding: Fusion.Value<{ Character.Character }, any>,
	BaseFull: Fusion.Value<boolean, any>,
	characterAdded: Signal.Signal,

	lockDuration: Fusion.Value<number, any>,
	lastLocked: Fusion.Value<number, any>,
	locked: Fusion.Value<boolean, any>,
}
export type Base = typeof(setmetatable({} :: self, Base))

function Base.new(model: Model): Base
	local self = setmetatable({}, Base) :: self

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
	self.characterAdded = Signal.new()

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
	Observer(scope, self.BaseFull):onChange(function()
		baseFull:FireAllClients(self.Id, peek(self.BaseFull))
	end)
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
				--if not RunService:IsStudio() then
				char:PivotTo(model:FindFirstChild("SpawnLocation"):GetPivot())
				--end
			end))
		end
	end)
	self.pirateOnDisplay = Charm.atom()
	subscribe(self.pirateOnDisplay, function(state)
		if self.displayModel then
			print(self.displayModel)
			self.displayModel:Destroy()
		end
		if state == nil then
			return
		end

		local displayModel = ReplicatedStorage.Assets.Models.Characters:FindFirstChild(state)
		if displayModel then
			displayModel = displayModel:Clone() :: Model
			local entrance: BasePart = self.Model:FindFirstChild("Entrance")
			displayModel:PivotTo(entrance:GetPivot() * CFrame.new(0, entrance.Size.Y / 2, 0))
			displayModel.Parent = self.Model
			for _, v in displayModel:GetDescendants() do
				if v:IsA("BasePart") then
					v.CollisionGroup = "Pirate"
				end
			end

			local hum = displayModel:FindFirstChildOfClass("Humanoid")
			local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
			animator.Parent = hum

			local track = animator:LoadAnimation(ReplicatedStorage.Assets.Animation.Idle)
			track.Looped = true
			track:Play()

			displayModel.PrimaryPart.Anchored = true
			displayModel:ScaleTo(6)
			displayModel:PivotTo(
				displayModel:GetPivot() * CFrame.new(0, (displayModel:GetExtentsSize().Y / 2) + 23, 10)
			)
			self.displayModel = displayModel
		end
	end)
	self._trove:Add(PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		if player == peek(self.player) then
			self:CalculateAndSetLockDuration()

			local playerProfile = PlayerDataServer.GetPlayerProfile(player)
			local pirateOnDisplay = playerProfile.Data.PirateOnDisplay
			if pirateOnDisplay ~= nil then
				self.pirateOnDisplay(pirateOnDisplay)
			end
		end
	end))

	self.platformsBeingStolen = self._scope:Value(0) :: Fusion.Value<number>
	-- local function checkSpeed()
	-- 	local ownerId = peek(self.Owner)
	-- 	if not ownerId then
	-- 		return
	-- 	end
	-- 	local player = Players:GetPlayerByUserId(ownerId)
	-- 	if player then
	-- 		local char: Model? = player.Character
	-- 		if char then
	-- 			local hum = char:FindFirstChildOfClass("Humanoid")
	-- 			if hum then
	-- 				hum.WalkSpeed = peek(self.platformsBeingStolen) > 0 and hum.WalkSpeed / 1.5
	-- 					or StarterPlayer.CharacterWalkSpeed
	-- 			end
	-- 		end
	-- 	end
	-- end
	--self._scope:Observer(self.platformsBeingStolen):onBind(checkSpeed)

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
		--playerTrove:Add(observeCharacter(player, checkSpeed))
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
			platform.trove:Add(platform.stolen:Connect(function()
				self.platformsBeingStolen:set(peek(self.platformsBeingStolen) + 1)

				remove()
			end))
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
	self.lockDuration = scope:Value(0)

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

		self.lastLocked:set(os.time())
		lockTrove:Add(RunService.Heartbeat:Connect(function()
			local playerProfile = PlayerDataServer.Profiles[player]
			if not playerProfile then
				return
			end
			if os.time() - peek(self.lastLocked) >= peek(self.lockDuration) then
				self:SetLocked(false)
			end
		end))
	end)

	self.unlockPrompt = self._scope:Hydrate(BaseUnlockPrompt:Clone())({
		ObjectText = self._scope:Computed(function(use)
			local ownerUserId = use(self.Owner)
			if ownerUserId then
				local player = Players:GetPlayerByUserId(ownerUserId)
				if player then
					return player.DisplayName
				end
			end
			return ""
		end),
		Parent = self.Model:FindFirstChild("Entrance"):FindFirstChild("EntrancePoint"),
		Enabled = self._scope:Computed(function(use)
			return use(self.locked) == true
		end),
	})
	self.unlockPrompt:AddTag("CustomPrompt")

	local playersAtEntrance = {}
	local playersInBase = {}

	local entranceWatcher = VolumeWatcher.new(model:FindFirstChild("Entrance"))
	entranceWatcher:SetWhitelist({ workspace })
	entranceWatcher.PlayerEntered.Event:Connect(function(player)
		if not table.find(playersAtEntrance, player) then
			table.insert(playersAtEntrance, player)
		end

		if player == peek(self.player) then
			local stealing = PlayerServer.players[tostring(player.UserId)].Stealing
			if peek(stealing.isStealing) and not peek(self.BaseFull) then
				PlayerDataServer.UpdateLeaderstat(player, "Steals", 1)
				self:AddCharacter(
					player,
					peek(stealing.characterStealingName),
					peek(stealing.characterStealingMutations)
				)
				stealing:CancelSteal()
			end
		end
	end)
	entranceWatcher.PlayerLeft.Event:Connect(function(player)
		local entranceIndex = table.find(playersAtEntrance, player)
		local baseIndex = table.find(playersInBase, player)
		if entranceIndex and not baseIndex then
			table.remove(playersAtEntrance, entranceIndex)
		end
	end)

	local baseWatcher = VolumeWatcher.new(model:FindFirstChild("BaseZone"))
	baseWatcher:SetWhitelist({ workspace })
	baseWatcher.PlayerEntered.Event:Connect(function(player)
		if not table.find(playersInBase, player) then
			table.insert(playersInBase, player)
		end

		local ownerPlayer = peek(self.player)
		if not ownerPlayer or player == ownerPlayer then
			return
		end
		if not table.find(playersAtEntrance, player) or peek(self.locked) then
			player:LoadCharacter()
		end
	end)
	baseWatcher.PlayerLeft.Event:Connect(function(player)
		local i = table.find(playersInBase, player)
		if i then
			table.remove(playersInBase, i)
		end
	end)

	return self
end

function Base.CalculateAndSetLockDuration(self: Base, customDuration: number?): ()
	local player = peek(self.player)
	if not player then
		return
	end
	local playerProfile = PlayerDataServer.Profiles[player]
	self.lockDuration:set(
		customDuration and customDuration
			or SharedData.LockedDuration
				+ (SharedRebirthData.Constants.LockTimerIncrement * math.min(
					playerProfile.Data.Leaderstats.Rebirths,
					SharedRebirthData.Constants.LockTimerMaxMult
				))
	)
end

function Base.AddCharacter(
	self: Base,
	player: Player,
	characterName: string,
	mutations: { string }?,
	savedData: SharedTypes.SavedPlatformData?,
	loadedIndex: number?
)
	mutations = mutations or {}

	local playerProfileData = PlayerDataServer.GetPlayerProfileData(player)

	if not table.find(playerProfileData.UnlockedCharacters, characterName) then
		table.insert(playerProfileData.UnlockedCharacters, characterName)
		IndexServer.unlockedNewCharacters:FireClient(player, { characterName })
	end

	local characterData = SharedSpawningData.Characters.Info[characterName]

	for i, v in self.platformsByIndex do
		if (loadedIndex and i ~= loadedIndex) or (tonumber(v.Model.Name) ~= i) then
			continue
		end
		if peek(v.CharacterData) == nil then
			if savedData then
				v.LastCollected = savedData.LastCollectedTime
			end

			v.Mutations:set(mutations)
			v.CharacterName:set(characterName)
			if not characterData then
				warn(`{characterName}'s data was not found`)
			end
			v.CharacterData:set(characterData)

			v:LoadGenerated()

			local state = table.clone(peek(self.CharactersInBase))
			state[i] = characterData
			self.CharactersInBase:set(state)

			if not savedData then
				playerProfileData.Platforms[i] = {
					LastCollectedTime = os.time(),
					CharacterName = characterName,
					Mutations = if #mutations > 0 then mutations else nil,
				}
			end

			self.characterAdded:Fire(characterName)

			break
		end
	end
end

function Base.AddCharacterAttempt(
	self: Base,
	player: Player,
	characterName: string,
	character: Character.Character,
	mutations: { string }?,
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

	self:AddCharacter(player, characterName, mutations, ignoreSave)
end

function Base.GetPlatformData(self: Base)
	local loadedPlatforms = {}
	for _, v in self.Platforms do
		local charName: string? = peek(v.CharacterName)
		if not charName then
			continue
		end
		local mutations = peek(v.Mutations)
		table.insert(loadedPlatforms, {
			platformId = v.Id,
			characterName = charName,
			lastCollectedTime = v.LastCollected,
			mutations = if #mutations > 0 then mutations else nil,
		})
	end
	return loadedPlatforms
end

function Base.SetLocked(self: Base, locked: boolean, customDuration: number?): ()
	self:CalculateAndSetLockDuration(customDuration)
	self.lastLocked:set(locked and os.time() or 0)
	self.locked:set(locked)
	Events.SetBaseLocked:FireAllClients(self.Id, locked, tostring(peek(self.lastLocked)), peek(self.lockDuration))
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
	self:ResetAllPlatforms(false)
	self.pirateOnDisplay(nil)
	Events.BaseReset:FireAllClients(self.Id)
end

function Base.ResetAllPlatforms(self: Base, remoreFromSave: boolean)
	for _, v in self.Platforms do
		v:Reset(remoreFromSave)
	end
end

function Base.Destroy(self: Base): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Base
