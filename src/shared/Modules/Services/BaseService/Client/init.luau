local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Platform = require(script.Base.Platform)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)
local Events = require(script.Events)

local Base = require(script.Base)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local peek = Fusion.peek

local player = Players.LocalPlayer

local BaseClient = {
	bases = {} :: { [string]: Base.Base },
}

function BaseClient.GetBase(): Base.Base
	for _, v in BaseClient.bases do
		if peek(v.Owner) == Players.LocalPlayer.UserId then
			return v
		end
	end
end

function BaseClient.init()
	local basesPlatformQueue: { [string]: { any } } = {}
	local charactersStolenQueue: { { baseId: string, platformId: string, playerStealing: Player? } } = {}
	local basesLoadQueue: { [string]: { SharedTypes.BaseSyncData } } = {}
	local basesResetQueue: { string } = {}
	local basesLockQueue: { [string]: string } = {}

	local function loadPlatform(platform: Platform.Platform, data)
		platform.LastCollected:set(data.lastCollectedTime)
		platform.CharacterName:set(data.characterName)
		platform:LoadGenerated()
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
				})
			end
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
		else
			table.insert(basesResetQueue, baseId)
		end
	end
	Net:Connect("BaseReset", resetBase)

	local function lockBase(baseId: string, lastLockedTime: string)
		local base = BaseClient.bases[baseId]
		if base then
			base.lastLocked:set(tonumber(lastLockedTime))
		else
			basesLockQueue[baseId] = lastLockedTime
		end
	end
	Net:Connect("BaseLocked", lockBase)

	local function characterStolen(baseId: string, platformId: string, playerStealing: Player?)
		local base = BaseClient.bases[baseId]
		if base then
			base.Platforms[platformId]:Stolen(playerStealing)
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
		}
	})
		for _, v in platforms do
			if BaseClient.bases[v.baseId] then
				loadPlatform(BaseClient.bases[v.baseId].Platforms[v.platformId], v)
			end
		end
	end)
	Net:Connect("BasePlatformCollected", function(baseId: string, platformId: string)
		pcall(function()
			BaseClient.bases[baseId].Platforms[platformId]:Collect()
		end)
	end)
	Net:Connect("BasePlatformSold", function(baseId: string, platformId: string)
		BaseClient.bases[baseId].Platforms[platformId]:Sold()
	end)

	observeCharacter(player, function(char)
		local platformBoardsContainer = Instance.new("Folder")
		platformBoardsContainer.Name = "PlatformBoardsContainer"
		platformBoardsContainer.Parent = player:WaitForChild("PlayerGui")
	end)

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
		local lastLockedTime = basesLockQueue[id]
		if lastLockedTime then
			lockBase(id, lastLockedTime)
			basesLockQueue[id] = nil
		end

		local resetIndex = table.find(basesResetQueue, id)
		if resetIndex then
			base:Reset()
			table.remove(basesResetQueue, resetIndex)
		end

		return function()
			base:Destroy()
			BaseClient.bases[instance] = nil
		end
	end)
end

return BaseClient
