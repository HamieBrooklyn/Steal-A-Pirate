local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local PopupServer = require(Services.PopupService.Server)
local IndexServer = require(Services.IndexService.Server)

local SharedTypes = require(script.Parent.Types)
local SharedData = require(script.Parent.Data)

local SharedSpawningData = require(Services.SpawningService.Data)

local Base = require(script.Base)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local peek = Fusion.peek

local BaseServer = {}

function BaseServer.GetPlayerBase(player: Player): Base.Base?
	for _, v in BaseServer.Bases do
		if peek(v.Owner) == player.UserId then
			return v
		end
	end
	warn(player.Name .. " did not have a base assigned")
end

function BaseServer.GivePlayerCharacter(player: Player, characterName: string, mutations: { string }?)
	local SpawningServer = require(Services.SpawningService.Server)

	local playerProfile = PlayerDataServer.GetPlayerProfile(player)
	if not playerProfile then
		return
	end
	local base = BaseServer.GetPlayerBase(player)
	if not base then
		return
	end

	if peek(base.BaseFull) then
		SpawningServer.AddCachedSpawnForPlayer(player, characterName)
	else
		base:AddCharacter(player, characterName, mutations)
	end
end

function BaseServer.init()
	local bases: { [string]: Base.Base } = {}
	Net:Handle("GetBases", function()
		local basesData = {}
		for _, v in bases do
			local ownerId = peek(v.Owner)
			if not ownerId then
				continue
			end
			table.insert(basesData, {
				baseId = v.Id,
				ownerId = ownerId,
				lastLockedTime = peek(v.lastLocked),
				platforms = v:GetPlatformData(),
			})
		end
		return basesData
	end)
	Players.PlayerAdded:Connect(function(player)
		for _, v in bases do
			if peek(v.Owner) == nil then
				v.Owner:set(player.UserId)
				return
			end
		end
		warn("No bases left for " .. player.Name)
	end)
	PlayerDataServer.PlayerProfileLoaded:Connect(function(player: Player)
		for _, base in bases do
			if peek(base.Owner) ~= player.UserId then
				continue
			end

			local playerProfileData = PlayerDataServer.GetPlayerProfileData(player)
			local charactersNotUnlockedNames = {}
			for i, savedPlatform: SharedTypes.SavedPlatformData in playerProfileData.Platforms do
				base:AddCharacter(player, savedPlatform.CharacterName, savedPlatform.Mutations, savedPlatform, i)

				if not table.find(playerProfileData.UnlockedCharacters, savedPlatform.CharacterName) then
					table.insert(charactersNotUnlockedNames, savedPlatform.CharacterName)
					table.insert(playerProfileData.UnlockedCharacters, savedPlatform.CharacterName)
				end
			end
			base:Load()

			IndexServer.unlockedNewCharacters:FireClient(player, charactersNotUnlockedNames)

			break
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, v in bases do
			if peek(v.Owner) == player.UserId then
				v.Owner:set(nil)
				v:Reset()
				return
			end
		end
	end)

	local function confirmBaseAndPlatform(player: Player, baseId: string, platformId: string)
		assert(typeof(baseId) == "string", "Base id was not of type string")
		assert(typeof(platformId) == "string", "Platform id was not of type string")

		local base: Base.Base = bases[baseId]
		assert(base, "Base model sent did not exist")

		local platform = base.Platforms[platformId]
		assert(platform, "Platform model sent did not exist in sent base model")

		return base, platform
	end

	Net:Connect("BaseCollectPlatform", function(player: Player, baseId: string, platformId: string)
		local base, platform = confirmBaseAndPlatform(player, baseId, platformId)
		if not platform then
			return
		end
		assert(peek(base.Owner) == player.UserId, player.Name .. " was not the owner of sent base")
		platform:Collect()
	end)
	Net:Connect("BasePlatformCharacterInteract", function(player: Player, baseId: string, platformId: string)
		local base, platform = confirmBaseAndPlatform(player, baseId, platformId)
		if not platform then
			return
		end
		assert(peek(platform.CharacterData) ~= nil, " there was no character assigned for sent platform")

		local ownerId = peek(base.Owner)
		assert(ownerId, "There is no owner at sent base")

		local charData = SharedSpawningData.Characters.Info[peek(platform.CharacterName)]

		if peek(base.Owner) == player.UserId then
			platform:Sell()
		else
			local stealingBase = BaseServer.GetPlayerBase(player)
			if peek(stealingBase.BaseFull) then
				PopupServer.SendPopupTo(player, {
					message = "Your base is full.",
					gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.RedApple,
				})
				return
			end
			if not Players:GetPlayerByUserId(ownerId):GetAttribute("IsInTutorial") then
				if charData.Stealable == false then
					PopupServer.SendPopupTo(player, {
						message = "This character is too sacred...",
						gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Haki.Conquerers,
					})
				else
					platform:Steal(player)
				end
			end
		end
	end)
	Net:Connect("LockBaseAttempt", function(player: Player, baseId: string)
		assert(typeof(baseId) == "string", "Base id was not of type string")

		local base: Base.Base = bases[baseId]
		assert(base, "Base model sent did not exist")
		assert(peek(base.Owner) == player.UserId, player.Name .. " was not the owner of sent base")

		if os.time() - peek(base.lastLocked) < peek(base.lockDuration) then
			return
		end

		base:SetLocked(true)
	end)

	Observers.observeTag(SharedData.Tag, function(instance)
		local base = Base.new(instance)
		bases[base.Id] = base
		return function()
			if bases[base.Id] then
				bases[base.Id] = nil
			end
			base:Destroy()
		end
	end)
	BaseServer.Bases = bases
end

return BaseServer
