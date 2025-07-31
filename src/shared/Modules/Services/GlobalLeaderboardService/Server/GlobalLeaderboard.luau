local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Emotes = ReplicatedStorage.Assets.Animation.Emotes:GetChildren()
local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local SharedTypes = require(script.Parent.Parent.Types)
local SharedData = require(script.Parent.Parent.Data)

local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Packages.Trove)
local glueCharacterToCurrentPosition =
	require(ReplicatedStorage.Shared.Modules.Utilities.glueCharacterToCurrentPosition)

local atom, subscribe = Charm.atom, Charm.subscribe

local GlobalLeaderboard = {}
GlobalLeaderboard.__index = GlobalLeaderboard

type self = {
	id: string,

	trove: Trove.Trove,

	statName: Charm.Atom<string>,
	maxListedPlayers: Charm.Atom<number>,
	isLeaderstat: Charm.Atom<boolean>,
	store: Charm.Atom<OrderedDataStore>,

	firstPlaceUserId: Charm.Atom<string?>,
	rigModel: Model,
	rigHumanoid: Humanoid,
	rigAnimator: Animator,
	rigAnimationTrack: AnimationTrack,

	lastList: { SharedTypes.ListItem },
}
export type GlobalLeaderboard = typeof(setmetatable({} :: self, GlobalLeaderboard))

function GlobalLeaderboard.new(instance: Model): GlobalLeaderboard
	local self = setmetatable({}, GlobalLeaderboard) :: GlobalLeaderboard

	local id = HttpService:GenerateGUID(false)
	instance:SetAttribute("GlobalLeaderboardId", id)
	self.id = id

	self.trove = Trove.new()
	local tempTrove = Trove.new()
	self.trove:Add(tempTrove)

	self.statName = atom()
	self.maxListedPlayers = atom(instance:GetAttribute("MaxListedPlayers") or 30)
	self.isLeaderstat = atom(instance:GetAttribute("IsLeaderstat") == true)

	self.lastList = {}

	self.firstPlaceUserId = atom()

	local firstSpawn = true

	local rigContainerModel = instance:FindFirstChild("First Place Avatar")
	self.rigModel = rigContainerModel:FindFirstChild("Rig")
	self.rigHumanoid = self.rigModel:FindFirstChildOfClass("Humanoid")
	self.rigAnimator = self.rigHumanoid:FindFirstChildOfClass("Animator")
	self.rigModel.Parent = ServerStorage
	subscribe(self.firstPlaceUserId, function(state)
		local firstPlaceExists = state ~= nil
		self.rigModel.Parent = firstPlaceExists and instance or ServerStorage

		tempTrove:Clean()
		for _, track in self.rigAnimator:GetPlayingAnimationTracks() do
			track:Stop()
		end
		if firstPlaceExists then
			local desc = Players:GetHumanoidDescriptionFromUserId(state)
			self.rigHumanoid.ApplyDescriptionFinished:Once(function()
				for _, v: NumberValue? in self.rigHumanoid:GetChildren() do
					if v:IsA("NumberValue") then
						v.Value += 1
					end
				end
				for _, v in self.rigModel:GetDescendants() do
					if v:IsA("BasePart") then
						v.CollisionGroup = "Character"
					end
				end
				if firstSpawn then
					firstSpawn = false
					task.delay(3, function()
						self.trove:Add(glueCharacterToCurrentPosition(self.rigModel))
					end)
				end
			end)
			self.rigHumanoid:ApplyDescription(desc)

			local newTrack = self.rigAnimator:LoadAnimation(Emotes[math.random(1, #Emotes)])
			newTrack.Looped = true
			tempTrove:Add(newTrack.Stopped:Connect(function()
				task.wait(0.1)
				newTrack:Play()
			end))
			newTrack:Play()
		end
	end)

	self.store = atom()
	self.trove:Add(subscribe(self.statName, function(state)
		self.store(DataStoreService:GetOrderedDataStore(state .. "_V0.1"))
	end))
	self.statName(instance:GetAttribute("StatName"))

	return self
end

function GlobalLeaderboard.Update(self: GlobalLeaderboard): ()
	local store = self.store()
	local statNameState = self.statName()
	for i, v in PlayerDataServer.Profiles do
		local amount = if self.isLeaderstat() then v.Data.Leaderstats[statNameState] else v.Data[statNameState]
		if i.UserId < 1 or table.find(SharedData.IgnoredUserIds, tostring(i.UserId)) or amount < 1 then
			continue
		end
		if typeof(amount) == "number" then
			store:SetAsync(tostring(i.UserId), math.round(amount))
		end
	end

	local pages = store:GetSortedAsync(false, self.maxListedPlayers())
	local updatedList = {}
	local page = pages:GetCurrentPage()
	for i, v in page do
		if v.value < 1 or tonumber(v.key) < 0 or table.find(SharedData.IgnoredUserIds, v.key) then
			table.remove(page, i)
		end
	end
	for i, v in page do
		if i == 1 then
			self.firstPlaceUserId(v.key)
		end
		updatedList[i] = v
	end
	self.lastList = updatedList
	return updatedList
end

function GlobalLeaderboard.Destroy(self: GlobalLeaderboard): ()
	self.trove:Destroy()
end

return GlobalLeaderboard
