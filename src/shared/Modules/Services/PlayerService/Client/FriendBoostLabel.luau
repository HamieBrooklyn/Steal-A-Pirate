local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)

local subscribe = Charm.subscribe

local FriendBoostLabel = {}
FriendBoostLabel.__index = FriendBoostLabel

type self = {}
export type FriendBoostLabel = typeof(setmetatable({} :: self, FriendBoostLabel))

function FriendBoostLabel.new(label: TextLabel, friendBoost: Charm.Atom<number>): FriendBoostLabel
	local self = setmetatable({}, FriendBoostLabel) :: FriendBoostLabel

	local function check(mult: number)
		label.Text = `Friend Boost: +{math.round((mult - 1) * 100)}%`
	end
	subscribe(friendBoost, check)
	check(friendBoost())

	return self
end

function FriendBoostLabel.Destroy(self: FriendBoostLabel): () end

return FriendBoostLabel
