local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Platform = require(script.Base.Platform)

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)
local Events = require(script.Events)

local Base = require(script.Base)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)

local peek = Fusion.peek

local player = Players.LocalPlayer

local BaseClient = {
	bases = {} :: { [string]: Base.Base },
}
BaseClient.characterAddedToBase = Signal.new()
BaseClient.characterRemovedFromBase = Signal.new()
BaseClient.baseLoaded = Signal.new()
BaseClient.baseReset = Signal.new()
BaseClient.platformsReset = Signal.new()

function BaseClient.GetBase()
	return Promise.new(function(resolve)
		for _, v in BaseClient.bases do
			if peek(v.Owner) == player.UserId then
				resolve(v)
				return
			end
		end
		local loadedCon: RBXScriptConnection
		loadedCon = BaseClient.baseLoaded:Connect(function(base: Base.Base)
			if peek(base.Owner) == player.UserId then
				loadedCon:Disconnect()
				resolve(base)
			end
		end)
	end)
end

function BaseClient.init()
	local basesPlatformQueue: { [string]: { any } } = {}
	local charactersStolenQueue: { { baseId: string, platformId: string, playerStealing: Player? } } = {}
	local basesLoadQueue: { [string]: { SharedTypes.BaseSyncData } } = {}
	local basesResetQueue: { string } = {}
	local basesSetLockedQueue: { [string]: string } = {}
	local basesFullQueue: { [string]: boolean } = {}

	local function loadPlatform(platform: Platform.Platform, data)
		platform.LastCollected:set(data.lastCollectedTime)
		platform.Mutations(data.mutations or {})
		platform.CharacterName:set(data.characterName)
		platform:LoadGenerated()

		local base = BaseClient.bases[data.baseId]
		if data.characterName and base then
			BaseClient.characterAddedToBase:Fire(base, data.characterName, platform)
		end
	end

	local function loadBase(baseData: SharedTypes.BaseSyncData)
		local baseId = baseData.baseId
		local ownerId = baseData.ownerId
		local base = BaseClient.bases[baseId]
		if base then
			base.Owner:set(ownerId)
			base.lastLocked:set(baseData.lastLockedTime)
			for _, v in baseData.platforms do
				loadPlatform(base.Platforms[v.platformId], {
					lastCollectedTime = v.lastCollectedTime,
					characterName = v.characterName,
					mutations = v.mutations,
				})
			end
			BaseClient.baseLoaded:Fire(base)
		else
			basesLoadQueue[baseId] = baseData
		end
	end
	local loadedBaseData: { SharedTypes.BaseSyncData } = Events.GetBases:InvokeServer()
	for _, v in loadedBaseData do
		loadBase(v)
	end
	Net:Connect("BaseLoaded", loadBase)

	local function resetBase(baseId: string)
		local base = BaseClient.bases[baseId]
		if base then
			base:Reset()
			BaseClient.baseReset:Fire(base)

			for _, v in base.Platforms do
				local charName = peek(v.CharacterName)
				if charName then
					BaseClient.characterRemovedFromBase:Fire(base, charName, v)
				end
			end
		else
			table.insert(basesResetQueue, baseId)
		end
	end
	Net:Connect("BaseReset", resetBase)

	Net:Connect("PlatformsReset", function(platformsReset: { SharedTypes.PlatformIdData })
		for _, v in platformsReset do
			local base = BaseClient.bases[v.baseId]
			if base then
				local platform = base.Platforms[v.platformId]
				if platform then
					platform:Reset()
				end
			end
		end
		BaseClient.platformsReset:Fire()
	end)

	local function setBaseLocked(baseId: string, isLocked: boolean, lastLockedTime: string, lockDuration: number)
		local base = BaseClient.bases[baseId]
		if base then
			base.locked:set(isLocked)
			base.lastLocked:set(tonumber(lastLockedTime))
			base.lockDuration:set(lockDuration)
			if base.lockButton then
				base.lockButton:Heartbeat()
			end
		else
			basesSetLockedQueue[baseId] = {
				isLocked = isLocked,
				lastLockedTime = lastLockedTime,
				lockDuration = lockDuration,
			}
		end
	end
	Net:Connect("SetBaseLocked", setBaseLocked)

	local function characterStolen(baseId: string, platformId: string, playerStealing: Player?)
		local base = BaseClient.bases[baseId]
		if base then
			local platform = base.Platforms[platformId]

			platform:Stolen(playerStealing)

			local charName = peek(platform.CharacterName)
			if charName then
				BaseClient.characterRemovedFromBase:Fire(base, charName, platform)
			end
		else
			table.insert(charactersStolenQueue, {
				baseId = baseId,
				platformId = platformId,
				playerStealing = playerStealing,
			})
		end
	end
	Net:Connect("BaseCharacterStolen", characterStolen)

	Net:Connect("BasePlatformCharacterSet", function(platforms: {
		{
			baseId: string,
			platformId: string,
			mutations: { string }?,
		}
	})
		for _, v in platforms do
			if BaseClient.bases[v.baseId] then
				pcall(function()
					loadPlatform(BaseClient.bases[v.baseId].Platforms[v.platformId], v)
				end)
			end
		end
	end)
	Net:Connect("BasePlatformCollected", function(baseId: string, platformId: string)
		BaseClient.bases[baseId].Platforms[platformId]:Collect()
	end)
	Net:Connect("BasePlatformSold", function(baseId: string, platformId: string)
		local base = BaseClient.bases[baseId]
		local platform = base.Platforms[platformId]

		platform:Sold()

		BaseClient.characterRemovedFromBase:Fire(base, peek(platform.CharacterName), platform)
	end)

	Net:Connect("PlayerIsStealing", function(isStealing: boolean, playerStealing: Player)
		BaseClient:GetBase():andThen(function(base: Base.Base)
			local playersStealingState = table.clone(peek(base.playersStealing))
			if isStealing then
				table.insert(playersStealingState, playerStealing)
			else
				local i = table.find(playersStealingState, playerStealing)
				if i then
					table.remove(playersStealingState, i)
				end
			end
			base.playersStealing:set(playersStealingState)
		end)
	end)

	local function setBaseFull(baseId: string, full: boolean)
		if BaseClient.bases[baseId] then
			BaseClient.bases[baseId].isFull:set(full)
		else
			basesFullQueue[baseId] = full
		end
	end
	Net:Connect("BaseIsFull", setBaseFull)

	Observers.observeTag(SharedData.Tag, function(instance)
		local base = Base.new(instance)

		local id = instance:GetAttribute("BaseId")
		BaseClient.bases[id] = base

		local platformsData = basesPlatformQueue[id]
		if platformsData then
			for _, v in platformsData do
				if instance:GetAttribute("BaseId") ~= v.baseId then
					continue
				end
				loadPlatform(base.Platforms[v.platformId], v)
			end
		end

		for i = #charactersStolenQueue, 1, -1 do
			local data = charactersStolenQueue[i]
			if data.baseId == id then
				characterStolen(id, data.platformId, data.playerStealing)
				table.remove(charactersStolenQueue, i)
			end
		end

		local baseData = basesLoadQueue[id]
		if baseData then
			loadBase(baseData)
			basesLoadQueue[id] = nil
		end
		local lockData = basesSetLockedQueue[id]
		if lockData then
			setBaseLocked(id, lockData.isLocked, lockData.lastLockedTime, lockData.lockDuration)
			basesSetLockedQueue[id] = nil
		end

		local resetIndex = table.find(basesResetQueue, id)
		if resetIndex then
			base:Reset()
			table.remove(basesResetQueue, resetIndex)
		end

		local isFull = basesFullQueue[id]
		if isFull then
			setBaseFull(id, isFull)
		end

		return function()
			base:Destroy()
			BaseClient.bases[instance] = nil
		end
	end)
end

return BaseClient
