local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local SharedTypes = require(script.Parent.Parent.Types)

local Charm = require(ReplicatedStorage.Packages.Charm)
local Trove = require(ReplicatedStorage.Packages.Trove)

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

	self.statName = atom()
	self.maxListedPlayers = atom(instance:GetAttribute("MaxListedPlayers") or 30)
	self.isLeaderstat = atom(instance:GetAttribute("IsLeaderstat") == true)

	self.lastList = {}

	self.firstPlaceUserId = atom()

	local rigContainerModel = instance:FindFirstChild("First Place Avatar")
	self.rigModel = rigContainerModel:FindFirstChild("Rig")
	self.rigHumanoid = self.rigModel:FindFirstChildOfClass("Humanoid")
	self.rigAnimator = self.rigHumanoid:FindFirstChildOfClass("Animator")
	self.rigAnimationTrack = self.rigAnimator:LoadAnimation(rigContainerModel:FindFirstChildOfClass("Animation"))
	self.rigModel.Parent = ServerStorage
	subscribe(self.firstPlaceUserId, function(state)
		local firstPlaceExists = state ~= nil
		self.rigModel.Parent = firstPlaceExists and instance or ServerStorage
		if firstPlaceExists then
			local desc = Players:GetHumanoidDescriptionFromUserId(state)
			self.rigHumanoid:ApplyDescription(desc)
			self.rigAnimationTrack:Play()
		else
			self.rigAnimationTrack:Stop()
		end
	end)

	self.store = atom()
	self.trove:Add(subscribe(self.statName, function(state)
		self.store(DataStoreService:GetOrderedDataStore(state))
	end))
	self.statName(instance:GetAttribute("StatName"))

	return self
end

function GlobalLeaderboard.Update(
	self: GlobalLeaderboard,
	sendUpdatedList: (list: { { key: string, value: number } }) -> ()
): ()
	local store = self.store()
	local statNameState = self.statName()
	for i, v in PlayerDataServer.Profiles do
		store:SetAsync(
			tostring(i.UserId),
			if self.isLeaderstat() then v.Data.Leaderstats[statNameState] else v.Data[statNameState]
		)
	end

	local pages = store:GetSortedAsync(false, self.maxListedPlayers())
	local updatedList = {}
	for i, v in pages:GetCurrentPage() do
		if i == 1 then
			self.firstPlaceUserId(v.key)
		end
		updatedList[i] = v
	end
	self.lastList = updatedList
	sendUpdatedList(updatedList)
end

function GlobalLeaderboard.Destroy(self: GlobalLeaderboard): ()
	self.trove:Destroy()
end

return GlobalLeaderboard
