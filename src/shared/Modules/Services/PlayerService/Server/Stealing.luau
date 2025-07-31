local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Characters = ReplicatedStorage.Assets.Models.Characters
local Services = ReplicatedStorage.Shared.Modules.Services

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)
local getMutationsString = require(ReplicatedStorage.Shared.Modules.Utilities.getMutationsString)

local scoped, peek = Fusion.scoped, Fusion.peek

local playerIsStealing = Net:RemoteEvent("PlayerIsStealing")

local Stealing = {}
Stealing.__index = Stealing

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	characterStealingName: Fusion.Value<string?, any>,
	characterStealingMutations: Fusion.Value<{ string }, any>,
	stealingFrom: Fusion.Value<Player?, any>,
	isStealing: Fusion.Value<boolean, any>,

	character: Fusion.Value<Model?, any>,
	humanoid: Fusion.Value<Humanoid?, any>,
	liftTrack: AnimationTrack?,
}
export type Stealing = typeof(setmetatable({} :: self, Stealing))

function Stealing.new(player: Player): Stealing
	local self = setmetatable({}, Stealing) :: Stealing

	local scope = scoped(Fusion)
	self.scope = scope

	local trove = Trove.new()
	self.trove = trove

	self.characterStealingName = scope:Value(nil)
	self.characterStealingMutations = scope:Value(nil)
	self.stealingFrom = scope:Value(nil)
	self.isStealing = scope:Value(false)

	scope:Observer(self.isStealing):onBind(function()
		local stealingFromPlayerState = peek(self.stealingFrom)
		local isStealingState = peek(self.isStealing)
		if isStealingState and stealingFromPlayerState then
			playerIsStealing:FireClient(stealingFromPlayerState, true, player)
		else
			if stealingFromPlayerState then
				playerIsStealing:FireClient(stealingFromPlayerState, false, player)
			end
		end
		player:SetAttribute("IsStealing", isStealingState)
	end)

	self.character = scope:Value(nil)
	self.humanoid = scope:Value(nil)
	trove:Add(observeCharacter(player, function(char)
		local charTrove = Trove.new()

		self.character:set(char)

		local hum = char:FindFirstChildOfClass("Humanoid")
		self.humanoid:set(hum)
		self.liftTrack = hum:FindFirstChildOfClass("Animator"):LoadAnimation(ReplicatedStorage.Assets.Animation.Lift)

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

		local char: Model?, hum: Humanoid? = peek(self.character), peek(self.humanoid)
		if not char or not hum or hum.Health < 1 then
			return
		end

		local nameState = peek(self.characterStealingName)
		hum.WalkSpeed = nameState == nil and StarterPlayer.CharacterWalkSpeed or StarterPlayer.CharacterWalkSpeed / 1.5
		if not nameState then
			return
		end

		local characterModel: Model = Characters:FindFirstChild(nameState):Clone()
		characterTrove:Add(characterModel)

		local mutationsState = peek(self.characterStealingMutations)
		if mutationsState and #mutationsState > 0 then
			local mString = getMutationsString(mutationsState)
			characterModel:SetAttribute("Mutations", mString)
			characterModel:AddTag("Mutated")
		end

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

function Stealing.StealCharacter(self: Stealing, fromPlayer: Player, characterName: string, mutations: { string })
	if peek(self.isStealing) then
		return
	end
	self.stealingFrom:set(fromPlayer)
	self.characterStealingMutations:set(mutations)
	self.characterStealingName:set(characterName)
	self.isStealing:set(true)
	if self.liftTrack then
		self.liftTrack:Play()
	end
end

function Stealing.CancelSteal(self: Stealing)
	local BaseServer = require(Services.BaseService.Server)
	local player = peek(self.stealingFrom)
	if player then
		local playerBase = BaseServer.GetPlayerBase(player)
		if playerBase then
			playerBase.platformsBeingStolen:set(math.max(peek(playerBase.platformsBeingStolen) - 1, 0))
		end
	end

	self.isStealing:set(false)
	self.stealingFrom:set(nil)
	self.characterStealingMutations:set(nil)
	self.characterStealingName:set(nil)
	if self.liftTrack then
		self.liftTrack:Stop()
	end
end

function Stealing.RetrieveCurrentStolenItem(self: Stealing)
	local BaseServer = require(Services.BaseService.Server)

	local player = peek(self.stealingFrom)
	if not player then
		return
	end

	local playerBase = BaseServer.GetPlayerBase(player)
	if playerBase and not peek(playerBase.BaseFull) then
		playerBase:AddCharacter(player, peek(self.characterStealingName), peek(self.characterStealingMutations))
		playerBase.platformsBeingStolen:set(math.max(peek(playerBase.platformsBeingStolen) - 1, 0))
	end
	self.isStealing:set(false)
	self.stealingFrom:set(nil)
	self.characterStealingName:set(nil)
	if self.liftTrack then
		self.liftTrack:Stop()
	end
end

function Stealing.Destroy(self: Stealing): ()
	if self.liftTrack then
		self.liftTrack:Stop()
	end
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Stealing
