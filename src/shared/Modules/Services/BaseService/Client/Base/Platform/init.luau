local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CashParticle = ReplicatedStorage.Assets.VFX.Particles.CashParticles
local InteractPromptTemp = ReplicatedStorage.Assets.Templates.PirateInteract

local SpawningServiceFold = ReplicatedStorage.Shared.Modules.Services.SpawningService
local Services = ReplicatedStorage.Shared.Modules.Services

local CollectorBoard = require(script.CollectorBoard)

local GuiAnimationClient = require(Services.GuiAnimationService.Client)
local PlayerDataClient = require(Services.PlayerDataService.Client)
local SettingsClient = require(Services.SettingsService.Client)
local PopupClient = require(Services.PopupService.Client)

local SharedRaritiesData = require(ReplicatedStorage.Shared.Modules.Data.Rarities)
local SharedSpawningTypes = require(SpawningServiceFold.Types)
local SharedSpawningData = require(SpawningServiceFold.Data)

local SharedData = require(script.Parent.Parent.Parent.Data)

local ScreenIconSpawner = require(ReplicatedStorage.Shared.Modules.Classes.ScreenIconSpawner)
local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)
local Particle = require(ReplicatedStorage.Shared.Modules.Classes.Particle)
local Sound = require(ReplicatedStorage.Shared.Modules.Classes.Sound)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Events = require(script.Parent.Parent.Events)
local Charm = require(ReplicatedStorage.Packages.Charm)
local Observers = require(ReplicatedStorage.Packages.Observers)
local ConfirmationMenu = require(ReplicatedStorage.Shared.Modules.Components.UI.ConfirmationMenu)
local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local atom = Charm.atom
local scoped, peek = Fusion.scoped, Fusion.peek

local player = Players.LocalPlayer

local Platform = {}
Platform.__index = Platform

type self = {
	id: string,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	model: Model,

	Owner: Fusion.Value<string?, any>,

	Generated: Charm.Atom<number>,
	Mutations: Charm.Atom<{ string }>,

	CharacterName: Fusion.Value<string?, any>,
	LastCollected: Fusion.Value<number?, any>,

	CharacterData: SharedSpawningTypes.CharacterData?,

	LocalPlayerIsOwner: Fusion.Value<boolean, any>,

	Emitter: Particle.Particle?,
	animatedHighlight: AnimatedHighlight.AnimatedHighlight,

	--getMultiplier: (number) -> number,
}
export type Platform = typeof(setmetatable({} :: self, Platform))

function Platform.new(
	model: Model,
	owner: Fusion.Value<string?, any>,
	baseModel: Model --getMultiplier: (number) -> number
): Platform
	local self = setmetatable({}, Platform) :: Platform

	self.id = model:GetAttribute("PlatformId")

	local scope = scoped(Fusion, {
		CollectorBoard = CollectorBoard,
	})
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	self.model = model

	self.Owner = owner
	self.Generated = atom(0)
	self.Mutations = atom({})

	--[[ self.getMultiplier = function(ownerId: number)
		local mutMult = 0
		for _, v in self.Mutations() do
			mutMult += SharedSpawningData.Mutations[v].Mult
		end
		return getMultiplier(ownerId) + mutMult
	end ]]

	local characterName = scope:Value(nil)
	self.CharacterName = characterName

	local hasConfirmPromptForPlatform = false

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
			local rarityData = SharedRaritiesData.Info[self.CharacterData.Rarity]

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
						return `{charModel.Name} {abbreviateNumber(self.CharacterData.Price / 2)}`
					end),
					HoldDuration = SharedData.PlatformUseHoldDuration,

					[Fusion.OnEvent("Triggered")] = function()
						if peek(self.Owner) == Players.LocalPlayer.UserId and hasConfirmPromptForPlatform then
							return
						end
						local function interact()
							if peek(self.CharacterName) then
								Events.PlatformCharacterInteract:FireServer(
									baseModel:GetAttribute("BaseId"),
									model:GetAttribute("PlatformId")
								)
							end
						end
						if
							table.find(SharedSpawningData.ImportantRarities, self.CharacterData.Rarity)
							and peek(self.LocalPlayerIsOwner)
						then
							hasConfirmPromptForPlatform = true
							ConfirmationMenu(self._scope, {
								parent = Players.LocalPlayer:WaitForChild("PlayerGui"),

								infoText = `Do you want to sell <font color="#{rarityData.PrimaryColor:ToHex()}">{peek(
									characterName
								)}</font> for <font color="#00FF22">{self.CharacterData.PriceString}</font>?`,

								confirmText = "Sell",
								exitText = "Cancel",

								confirmColor = Color3.fromHex("#FF2B63"),

								confirmed = interact,
								exited = function()
									hasConfirmPromptForPlatform = false
								end,
							}).Destroying:Once(function()
								hasConfirmPromptForPlatform = false
							end)
						else
							interact()
						end
					end,

					Enabled = enabled,
					Parent = attach,
				})
				rootTrove:Add(prompt)

				rootTrove:Add(Observers.observeAttribute(player, "IsStealing", function(stealing: boolean)
					enabled:set(if peek(self.Owner) ~= player.UserId and stealing then false else true)
				end))

				prompt:AddTag("CustomPrompt")
			end))
		end))
	end)

	local lastCollected = scope:Value(nil)
	self.LastCollected = lastCollected

	local adornee = scope:Value(nil)

	local collectPart = scope:Value(nil)
	self.CollectPart = collectPart

	local collectPartTrove = Trove.new()
	trove:Add(collectPartTrove)

	local touchDB = false
	local function checkCollectPart()
		collectPartTrove:Clean()

		local collectPartState: BasePart? = peek(collectPart)
		if not collectPartState then
			return
		end
		if peek(self.Owner) == player.UserId then
			self.Emitter = Particle.new(CashParticle, collectPartState)
			collectPartTrove:Add(self.Emitter)

			self.animatedHighlight = AnimatedHighlight.new({
				FillColor = Color3.fromRGB(0, 255, 140),
				OutlineColor = Color3.fromRGB(0, 255, 140),
				DepthMode = Enum.HighlightDepthMode.Occluded,
			})
			self.animatedHighlight.parent:set(collectPartState)
			collectPartTrove:Add(self.animatedHighlight)

			collectPartTrove:Add(collectPartState.Touched:Connect(function(hit: BasePart)
				local playerTouched = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
				if not playerTouched or peek(self.Owner) ~= playerTouched.UserId or self.Generated() < 1 or touchDB then
					return
				end
				touchDB = true
				task.delay(SharedData.CollectCooldown, function()
					touchDB = false
				end)

				Events.CollectPlatform:FireServer(baseModel:GetAttribute("BaseId"), model:GetAttribute("PlatformId"))
			end))
		end
	end

	self.LocalPlayerIsOwner = scope:Value(false)

	local collectStream = Streamable.new(model, "Collect")
	collectStream:Observe(function(part: BasePart, collectTrove: Trove.Trove)
		collectPart:set(part)
		adornee:set(part)
		if peek(self.Owner) then
			checkCollectPart()
			collectTrove:Add(checkCollectPart)
			collectTrove:Add(scope:CollectorBoard({
				Adornee = adornee,
				Parent = part,

				ownerId = self.Owner,

				Amount = self.Generated,
			}))
		end
	end)
	trove:Add(collectStream)
	scope:Observer(owner):onBind(function()
		self.LocalPlayerIsOwner:set(peek(owner) == player.UserId)
		checkCollectPart()
	end)

	return self
end

function Platform.Collect(self: Platform)
	self.Generated(0)
	self.LastCollected:set(os.time())

	local collectPart = peek(self.CollectPart)
	if collectPart then
		Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.CashCollect, collectPart):Play()
	end

	if peek(self.LocalPlayerIsOwner) and collectPart then
		local cashLabel: TextLabel? = player
			:WaitForChild("PlayerGui")
			:WaitForChild("Main")
			:WaitForChild("HUD")
			:WaitForChild("BottomSide")
			:WaitForChild("BottomContainer")
			:WaitForChild("Cash")

		local spawner
		spawner = ScreenIconSpawner.new(nil, {
			Icons = {
				["rbxassetid://76349172280125"] = math.clamp(math.floor(self.Generated() / 10), math.random(1, 2), 20),
			},
			WorldPart = collectPart,
			TargetPosition = UDim2.fromScale(0, 1),
		}, function()
			local animObj = GuiAnimationClient.animatedObjects[cashLabel]
			animObj.PositionSpring:addVelocity(UDim2.fromScale(0, -5))
			animObj.RotationSpring:addVelocity(math.random(-120, 120))
			animObj.AnimatedSize:addVelocity(UDim2.fromScale(0.1, 0.1))
		end, function()
			spawner:Destroy()
		end)
		if self.Emitter then
			self.Emitter:Emit(10)
		end
		if self.animatedHighlight then
			self.animatedHighlight:Pulse()
		end
	end
end

function Platform.LoadGenerated(self: Platform)
	self.Generated(
		math.abs(
			math.floor(
				(os.time() - peek(self.LastCollected))
					* (self.CharacterData.Cashflow * peek(PlayerDataClient.cashMultiplier))
			)
		)
	)
end

function Platform.Heartbeat(self: Platform)
	local data = self.CharacterData
	if data then
		local ownerUserId = peek(self.Owner)
		local mult = peek(PlayerDataClient.cashMultiplier)
		print(mult)

		local generated = math.abs(math.floor(self.Generated() + (data.Cashflow * mult)))
		if
			ownerUserId
			and SettingsClient.playerSettings[ownerUserId]
			and peek(SettingsClient.playerSettings[ownerUserId]["AutoCollect"])
		then
			if self.Generated() > 0 then
				self:Collect()
			end
		else
			self.Generated(generated)
		end

		if peek(self.LocalPlayerIsOwner) and self.Emitter then
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

	PopupClient.AddPopup({
		message = "Your pirate is being stolen!",
		gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.RedApple,
	})
	Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.Gui.Stealing, workspace):Play()
end

function Platform.Reset(self: Platform)
	self.LastCollected:set(nil)
	self.CharacterName:set(nil)
	self.CharacterData = nil
	task.spawn(function()
		local tries = 0
		repeat
			tries += 1
			self.Generated(0)
			task.wait()
		until tries >= 10
	end)
end

function Platform.Destroy(self: Platform): ()
	self.Generated(0)
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Platform
