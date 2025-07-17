local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Services = ReplicatedStorage.Shared.Modules.Services

local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)
local Path = require(script.Parent.Parent.Path)

local SpawningClient = require(Services.SpawningService.Client)

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Charm = require(ReplicatedStorage.Packages.Charm)

local atom, subscribe = Charm.atom, Charm.subscribe

local BuyCharacter = {}
BuyCharacter.__index = BuyCharacter

type self = {
	currentText: Fusion.Value<string, any>,
	highlight: AnimatedHighlight.AnimatedHighlight?,

	_trove: Trove.Trove,
}
export type BuyCharacter = typeof(setmetatable({} :: self, BuyCharacter))

function BuyCharacter.new(currentText: Fusion.Value<string, any>, texts: { [string]: string }, ...): BuyCharacter
	local self = setmetatable({}, BuyCharacter) :: BuyCharacter

	self._trove = Trove.new()

	self.currentText = currentText

	return self
end

function BuyCharacter.Start(
	self: BuyCharacter,
	texts: { [string]: string },
	spawnerName: string,
	characterName: string
): ()
	self.currentText:set(texts.Main)

	local path: Path.Path = self._trove:Add(Path.new())

	local charAtom: Charm.Atom<Model?> = atom()

	subscribe(charAtom, function(state)
		if self.highlight then
			self.highlight:Destroy()
			self.highlight = nil
		end
		if not state then
			return
		end

		self.highlight = AnimatedHighlight.new({ FillColor = Color3.new(1, 1, 1) }, charAtom())
		self.highlight.pulseLooping:set(true)
	end)

	self._trove:Add(RunService.Heartbeat:Connect(function()
		local player = Players.LocalPlayer
		local char = player.Character
		if not char then
			return
		end
		if char.PrimaryPart then
			path.fromAtom(char.PrimaryPart)
		end

		local spawner = SpawningClient.spawners[SpawningClient.spawnerIdByName[spawnerName]]
		if not spawner then
			return
		end
		local charsFold = spawner.folder:FindFirstChild("Characters")
		if charsFold then
			local closestChar: Model?
			local closestM = math.huge
			for _, v in charsFold:GetChildren() do
				if v.Name ~= characterName then
					continue
				end
				local m = (v:GetPivot().Position - char:GetPivot().Position).Magnitude
				if m < closestM then
					closestM = m
					closestChar = v
				end
			end
			if closestChar and closestChar.PrimaryPart then
				path.toAtom(closestChar.PrimaryPart)
				charAtom(closestChar)
			else
				charAtom(nil)
			end
		end
	end))
end

function BuyCharacter.Clean(self: BuyCharacter): ()
	self._trove:Destroy()
	self.highlight:Destroy()
end

return BuyCharacter
