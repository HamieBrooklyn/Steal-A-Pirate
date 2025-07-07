local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MoneyParticle = ReplicatedStorage.Assets.VFX.Particles.MoneyParticles
local InteractPromptTemp = ReplicatedStorage.Assets.Templates.PirateInteract

local SpawningServiceFold = ReplicatedStorage.Shared.Modules.Services.SpawningService

local CollectorBoard = require(script.CollectorBoard)

local GuiAnimationClient = require(ReplicatedStorage.Shared.Modules.Services.GuiAnimationService.Client)

local SharedSpawningTypes = require(SpawningServiceFold.Types)
local SharedSpawningData = require(SpawningServiceFold.Data)

local SharedData = require(script.Parent.Parent.Parent.Data)

local ScreenIconSpawner = require(ReplicatedStorage.Shared.Modules.Classes.ScreenIconSpawner)
local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)
local Particle = require(ReplicatedStorage.Shared.Modules.Classes.Particle)
local Toucher = require(ReplicatedStorage.Shared.Modules.Classes.Toucher)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(script.Parent.Parent.Events)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped, peek = Fusion.scoped, Fusion.peek

local player = Players.LocalPlayer

local Platform = {}
Platform.__index = Platform

type self = {
	id: string,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	model: Model,

	Generated: Fusion.Value<number, any>,
	LastGenerated: number,

	CharacterName: Fusion.Value<string?, any>,
	LastCollected: Fusion.Value<number?, any>,

	theif: Fusion.Value<Player?, any>,

	CharacterData: SharedSpawningTypes.CharacterData?,

	LocalPlayerIsOwner: Fusion.Value<boolean, any>,

	Emitter: Particle.Particle,
	animatedHighlight: AnimatedHighlight.AnimatedHighlight,
}
export type Platform = typeof(setmetatable({} :: self, Platform))

function Platform.new(model: Model, owner: Fusion.Value<string?, any>, baseModel: Model): Platform
	local self = setmetatable({}, Platform) :: Platform

	self.id = model:GetAttribute("PlatformId")

	local scope = scoped(Fusion, {
		CollectorBoard = CollectorBoard,
	})
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	self.model = model

	local generated = scope:Value(0)
	self.Generated = generated
	self.LastGenerated = 0

	local characterName = scope:Value(nil)
	self.CharacterName = characterName

	self.theif = scope:Value(nil)
	local stealingHighlightMarker = AnimatedHighlight.new({
		OutlineColor = Color3.fromRGB(255, 0, 38),
	})
	trove:Add(stealingHighlightMarker)
	scope:Observer(self.theif):onChange(function()
		local theifPlayer: Player? = peek(self.theif)
		if not theifPlayer then
			stealingHighlightMarker.pulseLooping:set(false)
			return
		end
		local theifChar = theifPlayer.Character
		if not theifChar then
			stealingHighlightMarker.pulseLooping:set(false)
			return
		end
		stealingHighlightMarker.parent:set(theifChar)
		stealingHighlightMarker.pulseLooping:set(true)
	end)

	local charTrove = Trove.new()
	scope:Observer(characterName):onChange(function()
		charTrove:Clean()

		local state = peek(self.CharacterName)
		self.CharacterData = if state then SharedSpawningData.Characters.Info[state] else nil

		if not state then
			return
		end
		local charModelStream = Streamable.new(model, state)
		charTrove:Add(charModelStream)
		charTrove:Add(charModelStream:Observe(function(charModel: Model, charModelTrove: Trove.Trove)
			local primaryStream = Streamable.primary(charModel)
			charModelTrove:Add(primaryStream)
			charModelTrove:Add(primaryStream:Observe(function(root: BasePart, rootTrove: Trove.Trove)
				local attach = scope:New("Attachment")({
					Position = Vector3.new(0, 0, -1.3),
					Parent = root,
				})
				rootTrove:Add(attach)

				local enabled = scope:Value(true)

				local prompt = scope:Hydrate(InteractPromptTemp:Clone())({
					ActionText = scope:Computed(function(use)
						return use(self.LocalPlayerIsOwner) and "Sell" or "Steal"
					end),
					ObjectText = scope:Computed(function()
						return `{charModel.Name} {peek(self.CharacterData).PriceString}`
					end),
					HoldDuration = SharedData.PlatformUseHoldDuration,

					[Fusion.OnEvent("Triggered")] = function()
						Events.PlatformCharacterInteract:FireServer(
							baseModel:GetAttribute("BaseId"),
							model:GetAttribute("PlatformId")
						)
					end,

					Enabled = enabled,
					Parent = attach,
				})
				rootTrove:Add(prompt)

				rootTrove:Add(Observers.observeAttribute(player, "IsStealing", function(isStealing)
					enabled:set(if isStealing and peek(owner) ~= player.UserId then false else true)
				end))

				prompt:AddTag("CustomPrompt")
			end))
			self.theif:set(nil)
		end))
	end)

	local lastCollected = scope:Value(nil)
	self.LastCollected = lastCollected

	local adornee = scope:Value(nil)

	local collectPart = scope:Value(nil)
	self.CollectPart = collectPart

	local touchTrove = Trove.new()
	trove:Add(touchTrove)

	self.Emitter = Particle.new(MoneyParticle, model:WaitForChild("Collect"))
	trove:Add(self.Emitter)

	self.animatedHighlight = AnimatedHighlight.new({
		FillColor = Color3.fromRGB(0, 255, 140),
		OutlineColor = Color3.fromRGB(0, 255, 140),
		DepthMode = Enum.HighlightDepthMode.Occluded,
	})
	trove:Add(self.animatedHighlight)

	local function checkToucher()
		touchTrove:Clean()
		if not peek(collectPart) then
			return
		end
		if peek(self.LocalPlayerIsOwner) then
			local toucher = Toucher.new(peek(collectPart))
			toucher.Cooldown = SharedData.CollectCooldown
			touchTrove:Add(toucher)

			touchTrove:Add(toucher.PlayerTouched:Connect(function(playerTouched: Player)
				if not peek(self.LocalPlayerIsOwner) or peek(self.Generated) < 1 then
					return
				end
				Events.CollectPlatform:FireServer(baseModel:GetAttribute("BaseId"), model:GetAttribute("PlatformId"))
			end))
		end
	end

	self.LocalPlayerIsOwner = scope:Value(false)

	local collectStream = Streamable.new(model, "Collect")
	collectStream:Observe(function(part: BasePart)
		collectPart:set(part)
		adornee:set(part)
		self.animatedHighlight.parent:set(part)
		checkToucher()
	end)
	trove:Add(collectStream)
	local observeCharCleanup
	scope:Observer(owner):onBind(function()
		if observeCharCleanup then
			observeCharCleanup()
			observeCharCleanup = nil
		end

		self.LocalPlayerIsOwner:set(peek(owner) == player.UserId)
		checkToucher()
	end)

	local board: BillboardGui?
	local disconnectCharObs: Fusion.Observer?
	local disconnectGeneratedObs: Fusion.Observer?
	observeCharCleanup = observeCharacter(player, function()
		if disconnectCharObs then
			disconnectCharObs()
			disconnectCharObs = nil
		end
		if disconnectGeneratedObs then
			disconnectGeneratedObs()
			disconnectGeneratedObs = nil
		end

		local function check()
			if peek(generated) > 0 then
				if not board or not board.Parent then
					board = scope:CollectorBoard({
						Adornee = adornee,
						Parent = player:WaitForChild("PlayerGui"):WaitForChild("PlatformBoardsContainer"),

						Amount = generated,
					})
				end
			else
				if board then
					board:Destroy()
					board = nil
				end
			end
		end
		disconnectCharObs = scope:Observer(characterName):onBind(check)
		disconnectGeneratedObs = scope:Observer(generated):onBind(check)
	end)

	return self
end

function Platform.Collect(self: Platform)
	self.LastGenerated = 0
	self.Generated:set(0)
	self.LastCollected:set(os.time())

	local collectPart = peek(self.CollectPart)
	if collectPart then
		Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.MoneyCollect, collectPart):Play()
	end

	if peek(self.LocalPlayerIsOwner) and collectPart then
		local moneyLabel: TextLabel? = player
			:WaitForChild("PlayerGui")
			:WaitForChild("Main")
			:WaitForChild("HUD")
			:WaitForChild("BottomContainer")
			:WaitForChild("Money")

		local spawner
		spawner = ScreenIconSpawner.new(nil, {
			Icons = {
				["rbxassetid://76349172280125"] = math.clamp(
					math.floor(self.LastGenerated / 10),
					math.random(1, 2),
					20
				),
			},
			WorldPart = collectPart,
			TargetPosition = UDim2.fromScale(0, 1),
		}, function()
			local animObj = GuiAnimationClient.AnimatedObjects[moneyLabel]
			animObj.PositionSpring:addVelocity(UDim2.fromScale(0, -5))
			animObj.RotationSpring:addVelocity(math.random(-120, 120))
			animObj.SizeSpring:addVelocity(UDim2.fromScale(0.1, 0.1))
		end, function()
			spawner:Destroy()
		end)
		self.Emitter:Emit(10)
		self.animatedHighlight:Pulse()
	end
end

function Platform.LoadGenerated(self: Platform)
	local generated = math.floor((os.time() - peek(self.LastCollected)) * self.CharacterData.Cashflow)
	self.Generated:set(generated)
	self.LastGenerated = generated
end

function Platform.Heartbeat(self: Platform)
	local data = self.CharacterData
	if data then
		local generated = math.floor(self.LastGenerated + data.Cashflow)
		self.Generated:set(generated)
		self.LastGenerated = generated

		if peek(self.LocalPlayerIsOwner) then
			self.Emitter:Emit(1)
		end
	end
end

function Platform.Sold(self: Platform)
	self:Reset()
end

function Platform.Stolen(self: Platform, playerStealing: Player)
	self.CharacterName:set(nil)
	self.CharacterData = nil

	if not peek(self.LocalPlayerIsOwner) then
		return
	end
	if not playerStealing then
		return
	end

	self.theif:set(playerStealing)
end

function Platform.Reset(self: Platform)
	self.CharacterName:set(nil)
	self.CharacterData = nil
	self.LastCollected:set(nil)
	self.Generated:set(0)
	self.LastGenerated = 0
	self.theif:set(nil)
end

function Platform.Destroy(self: Platform): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Platform
