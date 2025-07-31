local Players = game:GetService("Players")
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
local getWeightedRandom = require(ReplicatedStorage.Shared.Modules.Utilities.getWeightedRandom)
local Net = require(ReplicatedStorage.Packages.Net)
local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)

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
	characterDespawned: Signal.Signal,
	playerBoughtCharacter: Signal.Signal,

	CharactersByRarity: { [string]: { SharedTypes.CharacterData } },

	Random: Random,
}
export type Spawner = typeof(setmetatable({} :: self, Spawner))

function Spawner.new(spawnerFolder: Folder, data: SharedTypes.SpawnerData): Spawner
	local self = setmetatable({}, Spawner) :: self

	self.id = HttpService:GenerateGUID(false)
	spawnerFolder:SetAttribute("SpawnerId", self.id)

	self.QuestServer = require(Services.QuestService.Server)

	self.trove = Trove.new()
	self.scope = Fusion.scoped(Fusion)

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
	-- self.trove:Add(PlayerDataServer.newPlayerJoined:Connect(function(...)
	-- 	table.insert(self.guaranteedSpawnsQueue, self.Data.DefaultCharacter)
	-- end))

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
	self.characterDespawned = self.trove:Add(Signal.new()) :: Signal.Signal
	self.playerBoughtCharacter = self.trove:Add(Signal.new()) :: Signal.Signal

	self.Random = Random.new() -- Seed?

	self.guaranteeSpawnTexts = {}
	for i, _ in self.Data.RarityGuaranteeCooldowns do
		self.guaranteeSpawnTexts[i] = self.scope:Value("")
	end
	self.trove:Add(Net:Connect("GuratanteeTimesUpdated", function(id: string, rarity: string, newTimeString: string)
		if id == self.id then
			self.Data.RarityGuaranteeCooldowns[rarity] = tonumber(newTimeString)
		end
	end))

	local function doSide(side)
		local GuaranteeBoard = require(script.GuaranteeBoard)

		GuaranteeBoard(self.scope, {
			parent = self.Folder:FindFirstChild(side).PrimaryPart,
			adornee = self.Folder:FindFirstChild(side).PrimaryPart,
			rarityTexts = self.guaranteeSpawnTexts,
		})
	end
	doSide("Start")
	doSide("Finish")

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

	self.trove:Add(self.characterDespawned:Connect(function(character: Character.Character)
		if character.Character.Name ~= self.Data.DefaultCharacter then
			return
		end
		for _, player in self.QuestServer.beginnerPlayers do
			local base = BaseServer.GetPlayerBase(player)
			if base then
				local hasPirate = false
				for _, platform in base.Platforms do
					if peek(platform.CharacterName) then
						hasPirate = true
					end
				end
				if not hasPirate then
					local defaultPirateFound = false
					for _, v in self.SpawnedCharacters do
						if v.Character.Name == self.Data.DefaultCharacter and v.Character ~= character.Character then
							defaultPirateFound = true
						end
					end
					if not defaultPirateFound then
						table.insert(self.guaranteedSpawnsQueue, self.Data.DefaultCharacter)
					end
				end
			end
		end
	end))

	return self
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
		self.luckMultiplier,
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
				message = "Your base is full!",
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
			if profile.Data.Leaderstats.Cash < characterData.Price then
				PopupServer.SendPopupTo(player, {
					message = "You cant afford!",
					gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.RedApple,
				})
				return
			end
			PlayerDataServer.UpdateLeaderstat(player, "Cash", -characterData.Price)
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
	character._trove:Add(character.despawn:Connect(function()
		self.characterDespawned:Fire(character)
	end))
	table.insert(self.SpawnedCharacters, character)

	self.characterSpawned:Fire(characterName, character)
end

function Spawner.SpawnRandom(self: Spawner): ()
	self.LastSpawnedTime = time()

	if #self.guaranteedSpawnsQueue > 0 then
		self:SpawnCharacter(self.guaranteedSpawnsQueue[1])
		table.remove(self.guaranteedSpawnsQueue, 1)
	elseif #self.guaranteedSpawnsQueue == 0 then
		local charactersRange =
			self.CharactersByRarity[getWeightedRandom(Data.Spawning.RaritySpawnRates, self.luckMultiplier)]
		local characterName
		local tries = 0
		local function obtainable(charName: string)
			return Data.Characters.Info[charName] and Data.Characters.Info[charName].Natural == nil
				or Data.Characters.Info[charName].Natural == true
		end
		repeat
			characterName = charactersRange[self.Random:NextInteger(1, #charactersRange)]
			tries += 1
		until obtainable(characterName) or tries > 100
		if not obtainable(characterName) then
			return
		end
		self:SpawnCharacter(characterName)
	end
end

function Spawner.Heartbeat(self: Spawner)
	for _, character in self.SpawnedCharacters do
		character:UpdateMove()
	end

	for i, v in self.lastGuaranteedRaritySpawn do
		--print(i, self.Data.RarityGuaranteeCooldowns[i] - (os.time() - v))
		self.guaranteeSpawnTexts[i]:set(
			`Guranteed {i} In: {formatTime(self.Data.RarityGuaranteeCooldowns[i] - (os.time() - v))}`
		)
		if os.time() - v >= self.Data.RarityGuaranteeCooldowns[i] then
			self.lastGuaranteedRaritySpawn[i] = os.time()

			--updateGuaranteeTimes:FireAllClients(self.id, i, tostring(self.lastGuaranteedRaritySpawn[i]))
			local charactersRange = self.CharactersByRarity[i]
			if not charactersRange then
				continue
			end
			local tries = 0
			local charName
			repeat
				charName = charactersRange[self.Random:NextInteger(1, #charactersRange)]
				tries += 1
			until (Data.Characters.Info[charName].Natural == nil or Data.Characters.Info[charName].Natural == true)
				or tries > 100
			if
				not (Data.Characters.Info[charName].Natural == nil or Data.Characters.Info[charName].Natural == true)
			then
				return
			end
			table.insert(self.guaranteedSpawnsQueue, charName)
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
