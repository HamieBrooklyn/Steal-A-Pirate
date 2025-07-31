local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local InteractPromptTemp = ReplicatedStorage.Assets.Templates.PirateInteract
local AnimateScript = ReplicatedStorage.Assets.Templates.Animate

local SharedRarityData = require(ReplicatedStorage.Shared.Modules.Data.Rarities)
local SharedTypes = require(script.Parent.Parent.Types)
local SharedData = require(script.Parent.Parent.Data)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(script.Parent.Events)
local observeDescendants = require(ReplicatedStorage.Shared.Modules.Utilities.observeDescendants)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)
local Signal = require(ReplicatedStorage.Packages.Signal)

local getWeightedRandom = require(ReplicatedStorage.Shared.Modules.Utilities.getWeightedRandom)

local scoped, peek = Fusion.scoped, Fusion.peek

local mutations = {}
for _, v in script.Parent.Mutations:GetChildren() do
	mutations[v.Name] = require(v)
end

local Character = {}
Character.__index = Character

export type Character = typeof(setmetatable({} :: self, Character))
type self = {
	id: string,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	Player: Fusion.Value<Player, Player?>,
	TargetPosition: Fusion.Value<Vector3, Vector3?>,
	Status: Fusion.Value<string, string?>,

	Data: SharedTypes.CharacterData,

	Character: Model,
	Humanoid: Humanoid,
	Prompt: ProximityPrompt,

	despawn: Signal.Signal,
}

function Character.new(
	model: Model,
	data: SharedTypes.CharacterData,
	luckMult: number,
	spawnCFrame: CFrame,
	exitPosition: Vector3,
	parent: Instance?
): Character
	local self = setmetatable({}, Character) :: Character

	self.id = HttpService:GenerateGUID(false)

	local BaseServer = require(ReplicatedStorage.Shared.Modules.Services.BaseService.Server)
	self.BaseServer = BaseServer

	local scope = scoped(Fusion)
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	self.Status = scope:Value("MovingToExit")

	self.Data = data

	self.Character = model:Clone()
	self.Character:SetAttribute("CharacterId", self.id)
	trove:Add(self.Character)

	self.despawn = self._trove:Add(Signal.new()) :: Signal.Signal

	local mutationClassesApplied = {}
	local mutationsApplied = {}

	local mutationCount = 0
	for _, _ in SharedData.Mutations do
		mutationCount += 1
	end
	for _ = 1, mutationCount do
		local chosenMutation = getWeightedRandom(SharedData.Spawning.MutationChances, luckMult)
		local mutData = SharedData.Mutations[chosenMutation]
		if mutData and mutations[mutData.Class] and not table.find(mutationClassesApplied, mutData.Class) then
			table.insert(mutationClassesApplied, mutData.Class)
			table.insert(mutationsApplied, chosenMutation)
		end
	end
	for i, v in mutationsApplied do
		self.Character:SetAttribute(
			"Mutations",
			`{self.Character:GetAttribute("Mutations") or ""}{v}{i < #mutationsApplied and "," or ""}`
		)
	end
	if #mutationsApplied > 0 then
		self.Character:AddTag("Mutated")
	end

	local rarityData = SharedRarityData.Info[data.Rarity]
	if rarityData.CharacterHighlight then
		local hl = Instance.new("Highlight")
		hl.FillTransparency = 1
		hl.OutlineColor = rarityData.PrimaryColor
		hl.Parent = self.Character
	end

	local player = scope:Value(nil)
	self.Player = player

	trove:Add(observeDescendants(self.Character, function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = "Pirate"
		end
	end))

	if not RunService:IsStudio() then
		AnimateScript:Clone().Parent = self.Character
	end
	self.Character:AddTag(SharedData.Characters.Tag)

	self.Humanoid = self.Character:FindFirstChildOfClass("Humanoid")
	self.Humanoid.WalkSpeed = self.Character:GetAttribute("CustomWalkSpeed") or 16
	trove:Add(self.Humanoid.MoveToFinished:Connect(function()
		local state = peek(self.Player)

		local status = peek(self.Status)
		if status == "MovingToExit" then
			self.despawn:Fire()
			self:Destroy()
		elseif status == "MovingToBase" and state ~= nil then
			local base = BaseServer.GetPlayerBase(state)
			if base then
				base:AddCharacterAttempt(state, model.Name, self, mutationsApplied)
				self.despawn:Fire()
				self:Destroy()
			end
		end
	end))
	self.Humanoid.Running:Connect(function(speed)
		if not RunService:IsStudio() then
			for _, v in self.Humanoid:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks() do
				v:AdjustSpeed(speed / 10)
			end
		end
	end)
	self.Humanoid.WalkSpeed = SharedData.WalkSpeed

	local prompt = scope:Hydrate(InteractPromptTemp:Clone())({
		Parent = self.Character.PrimaryPart,
		RequiresLineOfSight = false,
		ActionText = scope:Computed(function(use)
			local status = use(self.Status)
			if status == "MovingToExit" then
				return "Buy"
			elseif status == "MovingToBase" then
				return "Steal"
			end
		end),
		ObjectText = scope:Computed(function(use)
			return `{model.Name} {data.PriceString}`
		end),
	})
	prompt:AddTag("CustomPrompt")
	self.Prompt = prompt

	self.Character:PivotTo(spawnCFrame)
	self.Character.Parent = parent
	self.Character.PrimaryPart:SetNetworkOwner(nil)

	local targetPos = scope:Value(nil)
	local lastPlayer: Player?
	local leavingCon: RBXScriptConnection?
	scope:Observer(player):onBind(function()
		if leavingCon then
			leavingCon:Disconnect()
			leavingCon = nil
		end

		local state: Player? = peek(player)
		if state ~= nil then
			Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.CharacterCollect, self.Character.PrimaryPart):Play()

			if lastPlayer then
				local lastBase = BaseServer.GetPlayerBase(lastPlayer)
				if lastBase then
					local charState = peek(lastBase.CharactersAdding)
					local i = table.find(charState, self)
					if i then
						table.remove(charState, i)
					end
					lastBase.CharactersAdding:set(charState)
				end
			end

			local base = BaseServer.GetPlayerBase(state)
			if base then
				targetPos:set(base.Model:FindFirstChild("CollectZone"):GetPivot().Position)

				local charState = peek(base.CharactersAdding)
				table.insert(charState, self)
				base.CharactersAdding:set(charState)

				self.Status:set("MovingToBase")
			end
			lastPlayer = state

			leavingCon = state.AncestryChanged:Connect(function(_, newParent)
				if newParent == nil then
					leavingCon:Disconnect()
					leavingCon = nil
					self.Player:set(nil)
				end
			end)
		else
			targetPos:set(exitPosition)
			self.Status:set("MovingToExit")
		end
		if not justSpawned then
			Events.CharacterMovingTo:FireAllClients(self.Character, state and tostring(state.UserId) or "")
		end
		justSpawned = false
	end)

	local moveCon: RBXScriptConnection?
	scope:Observer(targetPos):onBind(function()
		if moveCon then
			moveCon:Disconnect()
			moveCon = nil
		end
		self.Humanoid:MoveTo(peek(targetPos))
	end)
	self.TargetPosition = targetPos

	return self
end

function Character.UpdateMove(self: Character)
	local pos = peek(self.TargetPosition)
	if self.Humanoid and pos then
		self.Humanoid:MoveTo(pos)
	end
end

function Character.Destroy(self: Character): ()
	local state = peek(self.Player)
	if state then
		local base = self.BaseServer.GetPlayerBase(state)
		if base then
			local addedState = table.clone(peek(base.CharactersAdding))
			local i = table.find(addedState, self)
			if i then
				table.remove(addedState, i)
			end
			base.CharactersAdding:set(addedState)
		end
	end

	self._scope:doCleanup()
	self._trove:Destroy()
end

return Character
