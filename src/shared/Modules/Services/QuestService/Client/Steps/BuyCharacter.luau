local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services

local SpawningClient = require(Services.SpawningService.Client)

local AnimatedHighlight = require(Modules.Classes.AnimatedHighlight)

local observeCharacter = require(Modules.Utilities.observeCharacter)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)
local Path = require(script.Parent.Parent.Path)

local innerScope, peek = Fusion.innerScope, Fusion.peek

local BuyCharacter = {}
BuyCharacter.__index = BuyCharacter

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	text: Fusion.Value<string, any>,

	ended: Signal.Signal,
}
export type BuyCharacter = typeof(setmetatable({} :: self, BuyCharacter))

function BuyCharacter.new(scope: Fusion.Scope<any>, text: Fusion.Value<string, any>, ...): BuyCharacter
	local self = setmetatable({}, BuyCharacter) :: BuyCharacter

	self.scope = innerScope(scope)
	self.trove = Trove.new()

	self.text = text

	self.ended = Signal.new()
	self.trove:Add(self.ended)

	return self
end

function BuyCharacter.Started(self: BuyCharacter, spawnerName: string, characterName: string, texts: { string })
	self.text:set(texts[1])

	local path = Path.new(self.scope)
	local hl: AnimatedHighlight.AnimatedHighlight = self.trove:Add(AnimatedHighlight.new({
		FillColor = Color3.new(1, 1, 1),
	}, Players.LocalPlayer:WaitForChild("PlayerGui")))
	hl.pulseLooping:set(true)

	local character: Fusion.Value<Model?, any> = self.scope:Value(nil)
	local con: RBXScriptConnection?
	self.scope:Observer(character):onChange(function()
		if con then
			con:Disconnect()
			con = nil
		end

		local charState: Model? = peek(character)
		if not charState then
			hl.adornee:set(nil)
			return
		end
		con = charState.Destroying:Once(function()
			character:set(nil)
		end)

		path.to:set(charState.PrimaryPart)
		hl.adornee:set(charState)
	end)

	local charactersFold = workspace:WaitForChild(spawnerName):WaitForChild("Characters")
	local searchCon: RBXScriptConnection?
	self.trove:Add(observeCharacter(Players.LocalPlayer, function(char: Model)
		if searchCon then
			searchCon:Disconnect()
			searchCon = nil
		end

		path.from:set(char:WaitForChild("HumanoidRootPart"))

		searchCon = RunService.Heartbeat:Connect(function()
			local closestChar: Model
			local closestDist = math.huge
			for _, v: Model in charactersFold:GetChildren() do
				if not v:IsA("Model") or v.Name ~= characterName then
					continue
				end
				local dist = (char:GetPivot().Position - v:GetPivot().Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestChar = v
				end
			end
			character:set(closestChar)
		end)
	end))
	self.trove:Add(Net:Connect("SpawningBoughtCharacter", function(playerBought: Player, characterBoughtId: string)
		local isCorrectCharacter = SpawningClient.characters[characterBoughtId].model.Name == characterName
		if playerBought == Players.LocalPlayer and isCorrectCharacter then
			self.ended:Fire()
		end
	end))
end

function BuyCharacter.Destroy(self: BuyCharacter): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return BuyCharacter
