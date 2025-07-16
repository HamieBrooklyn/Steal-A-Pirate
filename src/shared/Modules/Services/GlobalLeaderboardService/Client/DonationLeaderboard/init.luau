local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ChoicesBoard = require(script.ChoicesBoard)

local New = Fusion.New
local scoped, doCleanup = Fusion.scoped, Fusion.doCleanup

local DonationLeaderboard = {}
DonationLeaderboard.__index = DonationLeaderboard

type self = {
	scope: Fusion.Scope<{
		ChoicesBoard: typeof(ChoicesBoard),
	}>,
	trove: Trove.Trove,
}
export type DonationLeaderboard = typeof(setmetatable({} :: self, DonationLeaderboard))

function DonationLeaderboard.new(model: Model): DonationLeaderboard
	local self = setmetatable({}, DonationLeaderboard) :: DonationLeaderboard

	self.scope = scoped(Fusion, {
		ChoicesBoard = ChoicesBoard,
	})
	self.trove = Trove.new()

	self.trove:Add(Streamable.new(model, "Choices"):Observe(function(part: BasePart, partTrove: Trove.Trove)
		partTrove:Add(self.scope:ChoicesBoard({
			parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
			adornee = part,
		}))
	end))

	return self
end

function DonationLeaderboard.Destroy(self: DonationLeaderboard): ()
	doCleanup(self.scope)
	self.trove:Destroy()
end

return DonationLeaderboard
