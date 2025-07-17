local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")

local Services = ReplicatedStorage.Shared.Modules.Services

local Characters = ReplicatedStorage.Assets.Models.Characters

local PlayerDataServer = require(Services.PlayerDataService.Server)
local PopupServer = require(Services.PopupService.Server)
local BaseServer = require(Services.BaseService.Server)

local Data = require(script.Parent.Parent.Data)

local SharedTypes = require(script.Parent.Parent.Types)
local Character = require(script.Parent.Character)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(script.Parent.Events)

local peek = Fusion.peek

local Spawner = {}
Spawner.__index = Spawner

type self = {
	id: string,

	trove: Trove.Trove,

	lastGuaranteedRaritySpawn: { [string]: number },
	guaranteedSpawnsQueue: { string },

	luckMultiplier: number,
	lastLuckBoost: number,
	luckDuration: number,

	Folder: Folder,
	StartPortal: Model,
	FinishPortal: Model,

	Data: SharedTypes.SpawnerData,

	LastSpawnedTime: number,
	SpawnedCharacters: { Character.Character },

	characterSpawned: Signal.Signal,
	playerBoughtCharacter: Signal.Signal,

	CharactersByRarity: { [string]: { SharedTypes.CharacterData } },

	Random: Random,
}
export type Spawner = typeof(setmetatable({} :: self, Spawner))

function Spawner.new(spawnerFolder: Folder, data: SharedTypes.SpawnerData): Spawner
	local self = setmetatable({}, Spawner) :: self

	self.id = HttpService:GenerateGUID(false)
	spawnerFolder:SetAttribute("SpawnerId", self.id)

	self.trove = Trove.new()

	self.Folder = spawnerFolder
	self.StartPortal = spawnerFolder:FindFirstChild("Start")
	self.FinishPortal = spawnerFolder:FindFirstChild("Finish")

	self.luckMultiplier = 1
	self.lastLuckBoost = -1
	self.luckDuration = 0

	self.Data = data

	--self.defaultSpawnsRequired = 0
	self.lastGuaranteedRaritySpawn = {}
	for i, _ in self.Data.RarityGuaranteeCooldowns do
		self.lastGuaranteedRaritySpawn[i] = os.time()
	end

	self.guaranteedSpawnsQueue = {}
	self.trove:Add(PlayerDataServer.newPlayerJoined:Connect(function(...)
		table.insert(self.guaranteedSpawnsQueue, self.Data.DefaultCharacter)
	end))

	self.possibleSpawns = {}
	if data.Whitelist and #data.Whitelist > 0 then
		self.possibleSpawns = data.Whitelist
	elseif data.Blacklist then
		for i, _ in Data.Characters.Info do
			if not table.find(data.Blacklist, i) then
				table.insert(self.possibleSpawns, i)
			end
		end
	end

	self.LastSpawnedTime = time()
	self.SpawnedCharacters = {}

	self.characterSpawned = self.trove:Add(Signal.new()) :: Signal.Signal
	self.playerBoughtCharacter = self.trove:Add(Signal.new()) :: Signal.Signal

	self.Random = Random.new() -- Seed?

	local charactersByRarity = {}
	for _, v in self.possibleSpawns do
		local characterData = Data.Characters.Info[v]
		if not characterData then
			warn(v .. " has not been added to character data")
			continue
		end
		if not charactersByRarity[characterData.Rarity] then
			charactersByRarity[characterData.Rarity] = {}
		end
		characterData = table.clone(characterData)
		characterData.Name = v
		table.insert(charactersByRarity[characterData.Rarity], v)
	end
	self.CharactersByRarity = charactersByRarity

	return self
end

function Spawner.ChooseRandomRarity(self: Spawner)
	local totalWeight = 0

	local rarities = {}
	for rarity, _ in self.CharactersByRarity do
		local weight = Data.Spawning.RaritySpawnRates[rarity]
		totalWeight += weight
		rarities[rarity] = weight
	end

	local randomValue = math.random() * totalWeight
	local current = 0

	for rarity, weight in rarities do
		current += weight * (if weight < 0.1 then self.luckMultiplier else 1)
		if randomValue <= current then
			return rarity
		end
	end
end

function Spawner.SpawnCharacter(self: Spawner, characterName: string)
	local characterData: SharedTypes.CharacterData = Data.Characters.Info[characterName]
	local characterModel = Characters:FindFirstChild(characterName)
	if not characterModel then
		warn(characterName .. " was not found as a character model")
		return
	end
	local character = Character.new(
		characterModel,
		characterData,
		self.StartPortal:GetPivot(),
		self.FinishPortal:GetPivot().Position,
		self.Folder:FindFirstChild("Characters")
	)
	character._trove:Add(character.Prompt.Triggered:Connect(function(player: Player)
		local base = BaseServer.GetPlayerBase(player)
		if not base then
			return
		end
		if peek(base.BaseFull) == true then
			PopupServer.SendPopupTo(player, {
				message = "Your base if full!",
				gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.RedApple,
			})
			return
		end

		local currentPlayer: Player = peek(character.Player)
		if currentPlayer and currentPlayer:GetAttribute("IsInTutorial") then
			return
		end

		local profile = PlayerDataServer.GetPlayerProfile(player)
		if profile then
			if profile.Data.Leaderstats.Beli < characterData.Price then
				return
			end
			PlayerDataServer.UpdateLeaderstat(player, "Beli", -characterData.Price)
			character.Player:set(player)

			self.playerBoughtCharacter:Fire(player, character)
			Events.BoughtCharacter:FireAllClients(player, character.id)

			AnalyticsService:LogFunnelStepEvent(player, "BoughtCharacter", _G.funnelSessionId, 1, characterName)
		end
	end))
	character._trove:Add(function()
		local i = table.find(self.SpawnedCharacters, character)
		if i then
			table.remove(self.SpawnedCharacters, i)
		end
	end)
	table.insert(self.SpawnedCharacters, character)

	self.characterSpawned:Fire(characterName, character)
end

function Spawner.SpawnRandom(self: Spawner): ()
	self.LastSpawnedTime = time()

	local charactersRange = self.CharactersByRarity[self:ChooseRandomRarity()]
	local characterName = charactersRange[self.Random:NextInteger(1, #charactersRange)]
	if #self.guaranteedSpawnsQueue > 0 then
		self:SpawnCharacter(self.guaranteedSpawnsQueue[1])
		table.remove(self.guaranteedSpawnsQueue, 1)
	else
		self:SpawnCharacter(characterName)
	end
end

function Spawner.Heartbeat(self: Spawner)
	for _, character in self.SpawnedCharacters do
		character:UpdateMove()
	end

	for i, v in self.lastGuaranteedRaritySpawn do
		if os.time() - v > self.Data.RarityGuaranteeCooldowns[i] then
			self.lastGuaranteedRaritySpawn[i] = os.time()
			local charactersRange = self.CharactersByRarity[i]
			if not charactersRange then
				continue
			end
			table.insert(self.guaranteedSpawnsQueue, charactersRange[self.Random:NextInteger(1, #charactersRange)])
		end
	end

	if time() - self.LastSpawnedTime >= self.Data.SpawnCooldown then
		self:SpawnRandom()
	end

	if self.lastLuckBoost ~= -1 and time() - self.lastLuckBoost >= self.luckDuration then
		self.lastLuckBoost = -1
		self.luckMultiplier = 1
		self.luckDuration = 0
		PopupServer.SendServerPopup({
			message = `Luck boost has ended at {self.Folder.Name}`,
			duration = 5,
			gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.RedApple,
		})
	end
end

function Spawner.ActivateLuckBoost(self: Spawner, multiplier: number, duration: number): ()
	if multiplier >= self.luckMultiplier and duration > time() - self.lastLuckBoost then
		self.luckDuration = duration
		self.lastLuckBoost = time()
		self.luckMultiplier = multiplier
	end
end

function Spawner.Destroy(self: Spawner): ()
	self.trove:Destroy()
end

return Spawner
