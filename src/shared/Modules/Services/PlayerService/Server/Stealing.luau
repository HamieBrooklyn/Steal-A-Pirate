local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = ReplicatedStorage.Assets.Models.Characters
local Services = ReplicatedStorage.Shared.Modules.Services

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local scoped, peek = Fusion.scoped, Fusion.peek

local Stealing = {}
Stealing.__index = Stealing

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	characterStealingName: Fusion.Value<string?, any>,
	stealingFrom: Fusion.Value<Player?, any>,
	isStealing: Fusion.Value<boolean, any>,

	character: Fusion.Value<Model?, any>,
	humanoid: Fusion.Value<Humanoid?, any>,
}
export type Stealing = typeof(setmetatable({} :: self, Stealing))

function Stealing.new(player: Player): Stealing
	local self = setmetatable({}, Stealing) :: Stealing

	local scope = scoped(Fusion)
	self.scope = scope

	local trove = Trove.new()
	self.trove = trove

	self.characterStealingName = scope:Value(nil)
	self.stealingFrom = scope:Value(nil)
	self.isStealing = scope:Value(false)

	scope:Observer(self.isStealing):onBind(function()
		player:SetAttribute("IsStealing", peek(self.isStealing))
	end)

	self.character = scope:Value(nil)
	self.humanoid = scope:Value(nil)
	trove:Add(observeCharacter(player, function(char)
		local charTrove = Trove.new()

		self.character:set(char)
		self.humanoid:set(char:FindFirstChildOfClass("Humanoid"))

		charTrove:Add(peek(self.humanoid).Died:Connect(function()
			if peek(self.stealingFrom) and peek(self.characterStealingName) then
				self:RetrieveCurrentStolenItem()
			end
		end))

		return function()
			charTrove:Destroy()
		end
	end))

	local characterTrove = Trove.new()
	scope:Observer(self.characterStealingName):onBind(function()
		characterTrove:Clean()

		local nameState = peek(self.characterStealingName)
		if not nameState then
			return
		end

		local char: Model?, hum: Humanoid? = peek(self.character), peek(self.humanoid)
		if not char or not hum or hum.Health < 1 then
			return
		end

		local characterModel: Model = Characters:FindFirstChild(nameState):Clone()
		characterTrove:Add(characterModel)

		for _, v in characterModel:GetDescendants() do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.CanTouch = false
				v.CanQuery = false
				v.Massless = true
			end
			if v:IsA("Humanoid") then
				v.PlatformStand = true
			end
		end
		characterModel:PivotTo(char:GetPivot())

		scope:New("Weld")({
			Part0 = characterModel.PrimaryPart,
			Part1 = char:FindFirstChild("UpperTorso"),
			C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(90), 0, 0),
			C1 = CFrame.new(0, 3, 0),
			Parent = characterModel.PrimaryPart,
		})

		characterModel.Parent = char
	end)

	return self
end

function Stealing.StealCharacter(self: Stealing, fromPlayer: Player, characterName: string)
	if peek(self.isStealing) then
		return
	end
	self.stealingFrom:set(fromPlayer)
	self.characterStealingName:set(characterName)
	self.isStealing:set(true)
end

function Stealing.CancelSteal(self: Stealing)
	self.stealingFrom:set(nil)
	self.characterStealingName:set(nil)
	self.isStealing:set(false)
end

function Stealing.RetrieveCurrentStolenItem(self: Stealing)
	local BaseServer = require(Services.BaseService.Server)

	local player = peek(self.stealingFrom)
	local playerBase = BaseServer.GetPlayerBase(player)
	print(peek(playerBase.BaseFull))
	if playerBase and not peek(playerBase.BaseFull) then
		playerBase:AddCharacter(player, peek(self.characterStealingName))
		print("added")
	end
	self.stealingFrom:set(nil)
	self.characterStealingName:set(nil)
	self.isStealing:set(false)
end

function Stealing.Destroy(self: Stealing): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Stealing
