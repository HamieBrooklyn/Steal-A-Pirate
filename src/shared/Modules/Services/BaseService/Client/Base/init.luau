local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services
local RebirthService = Services.RebirthService

local MonitizationClient = require(Services.MonitizationService.Client)
local PlayerDataClient = require(Services.PlayerDataService.Client)
local RebirthClient = require(RebirthService.Client)

local observeChildren = require(Modules.Utilities.observeChildren)

local CashMultBoard = require(script.CashMultBoard)
local Platform = require(script.Platform)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local LockButton = require(script.LockButton)
local Toucher = require(Modules.Classes.Toucher)
local AnimatedHighlight = require(Modules.Classes.AnimatedHighlight)
local BasePointer = require(Services.BaseService.Client.Base.BasePointer)

local scoped, peek = Fusion.scoped, Fusion.peek

local Base = {}
Base.__index = Base

type self = {
	Id: string,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	model: Model,

	Owner: Fusion.Value<string, any>,

	lastLocked: Fusion.Value<number, any>,
	lockDuration: Fusion.Value<number, any>,
	locked: Fusion.Value<boolean, any>,
	isFull: Fusion.Value<boolean, any>,

	playersStealing: Fusion.Value<{ Player }>,

	lockButton: LockButton.LockButton?,

	Platforms: { [string]: Platform.Platform },
}
export type Base = typeof(setmetatable({} :: self, Base))

--[[ function getMultiplier(ownerId: number, ignoreFriendBoost: boolean?)
	if not ownerId then
		return 1
	end

	local mult = 0
	if
		ownerId
		and MonitizationClient.playerGamepasses[ownerId]
		and peek(MonitizationClient.playerGamepasses[ownerId]["2XMoney"]) == true
	then
		mult += 2
	end
	if not ignoreFriendBoost and PlayerClient.friendBoostMult and (PlayerClient.friendBoostMult() - 1) > 0 then
		mult += (PlayerClient.friendBoostMult() - 1)
	end
	mult += peek(RebirthClient.data.Constants.CashMultiplier * peek(RebirthClient.rebirths))

	if mult < 1 then
		mult += 1
	end

	-- print(mult)
	return mult
end ]]

function Base.new(model: Model): Base
	local self = setmetatable({}, Base) :: Base

	self.Id = model:GetAttribute("BaseId")

	local scope = scoped(Fusion)
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	self.model = model

	local owner = scope:Value(nil)
	self.Owner = owner

	self.lockDuration = scope:Value(0)
	self.lastLocked = scope:Value(0)
	self.locked = scope:Value(false)
	self.isFull = scope:Value(false)

	self.playersStealing = scope:Value({})

	local stealingTrove = Trove.new()
	self._trove:Add(stealingTrove)

	self._scope:Observer(self.playersStealing):onBind(function()
		stealingTrove:Clean()
		local playersStealingState = peek(self.playersStealing)
		for _, v: Player in playersStealingState do
			local function charAdded(char: Model?)
				local stealingHighlightMarker: AnimatedHighlight.AnimatedHighlight =
					stealingTrove:Add(AnimatedHighlight.new({
						OutlineColor = Color3.fromRGB(255, 0, 38),
					}, char))
				stealingHighlightMarker.pulseLooping:set(true)
			end
			stealingTrove:Add(v.CharacterAdded:Connect(charAdded))
			charAdded(v.Character)
		end
	end)

	local platforms: { Platform.Platform } = {}
	self.Platforms = platforms

	local cashMultText = self._scope:Value("")
	local function checkMultiplierText()
		cashMultText:set(`x{math.floor(peek(PlayerDataClient.cashMultiplier) * 100) / 100}`)
	end
	PlayerDataClient.LeaderstatsLoaded:Connect(function()
		self._scope:Observer(RebirthClient.rebirths):onBind(checkMultiplierText)
	end)

	self._trove:Add(
		Streamable.new(model, "Monitization"):Observe(function(monitizationFold: Folder, foldTrove: Trove.Trove)
			foldTrove:Add(observeChildren(monitizationFold, function(part: BasePart?)
				local productData = MonitizationClient.data.Products[part.Name]
				if part:IsA("BasePart") and productData then
					local toucher: Toucher.Toucher = foldTrove:Add(Toucher.new(part))
					foldTrove:Add(toucher.PlayerTouched:Connect(function(playerTouched: Player)
						if
							playerTouched == Players.LocalPlayer
							and (not MonitizationClient.playerGamepasses[playerTouched.UserId] or not peek(
								MonitizationClient.playerGamepasses[playerTouched.UserId][part.Name]
							))
							and peek(self.Owner) == playerTouched.UserId
							and not playerTouched.Character:GetAttribute("Ragdolled")
						then
							MonitizationClient.PromptPurchase(productData.Id)
						end
					end))
					return function()
						if toucher then
							toucher:Destroy()
						end
					end
				end
			end))
		end)
	)

	local lockButton: LockButton.LockButton?
	local lockButtonStream = Streamable.new(model, "LockBase")
	trove:Add(lockButtonStream)
	trove:Add(lockButtonStream:Observe(function(button: BasePart, lockButtonTrove: Trove.Trove)
		lockButton = LockButton.new(button, {
			lastLocked = self.lastLocked,
			lockDuration = self.lockDuration,
			locked = self.locked,

			owner = self.Owner,
			baseId = self.Id,
		})
		self.lockButton = lockButton
		lockButtonTrove:Add(lockButton)
		lockButtonTrove:Add(function()
			lockButton = nil
		end)
	end))
	scope:Observer(self.lastLocked):onChange(function()
		if lockButton then
			lockButton:Heartbeat()
		end
	end)

	local heartbeatCon: RBXScriptConnection?
	local ownerTrove = Trove.new()
	scope:Observer(owner):onChange(function()
		checkMultiplierText()
		ownerTrove:Clean()

		if heartbeatCon then
			heartbeatCon:Disconnect()
			heartbeatCon = nil
		end
		if not peek(owner) then
			return
		end

		local collectStream = ownerTrove:Add(Streamable.new(model, "CollectZone"))
		ownerTrove:Add(collectStream:Observe(function(collectZonePart: BasePart, collectZoneTrove: Trove.Trove)
			if peek(self.Owner) == Players.LocalPlayer.UserId then
				collectZoneTrove:Add(CashMultBoard(self._scope, {
					adornee = collectZonePart,
					parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),

					text = cashMultText,
				}))
			end
		end))

		ownerTrove:Add(observeChildren(model:FindFirstChild("Platforms"), function(platformModel)
			if not platformModel:IsA("Model") then
				return
			end
			local platform = Platform.new(platformModel, owner, model, getMultiplier)
			ownerTrove:Add(platform)
			platforms[platformModel:GetAttribute("PlatformId")] = platform
		end))

		local lastCheck = time()
		heartbeatCon = RunService.Heartbeat:Connect(function()
			if time() - lastCheck < 1 then
				return
			end
			lastCheck = time()

			if lockButton then
				lockButton:Heartbeat()
			end

			for _, v in platforms do
				if not v.CharacterData then
					continue
				end
				v:Heartbeat()
			end
		end)

		local entranceStreamable = ownerTrove:Add(Streamable.new(model, "Entrance"))
		ownerTrove:Add(entranceStreamable:Observe(function(entrance: Part, entranceTrove: Trove.Trove)
			if peek(self.Owner) == Players.LocalPlayer.UserId then
				entranceTrove:Add(BasePointer(self._scope, {
					Parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
					Adornee = entrance,
				}))
			end

			local entrancePointStream = entranceTrove:Add(Streamable.new(entrance, "EntrancePoint"))
			entranceTrove:Add(entrancePointStream:Observe(function(attach: Attachment, attachTrove: Trove.Trove)
				local promptStream = attachTrove:Add(Streamable.new(attach, "BaseUnlock"))
				promptStream:Observe(function(prompt: ProximityPrompt, promptTrove: Trove.Trove)
					local function check()
						prompt.Enabled = peek(owner) ~= Players.LocalPlayer.UserId and peek(self.locked) == true
					end
					promptTrove:Add(self._scope:Observer(owner):onBind(check))
					promptTrove:Add(self._scope:Observer(self.locked):onBind(check))
					promptTrove:Add(prompt.Triggered:Connect(function()
						local ownerId = peek(self.Owner)
						if ownerId then
							local ownerPlayer = Players:GetPlayerByUserId(ownerId)
							if ownerPlayer then
								local id = MonitizationClient.data.Products["UnlockBase"].Id
								MonitizationClient.SetPrompting(id)
								MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
							end
						end
					end))
				end)
			end))
		end))
	end)

	return self
end

function Base.Reset(self: Base)
	self.Owner:set(nil)
	for _, v in self.Platforms do
		v:Reset()
	end
end

function Base.Destroy(self: Base): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Base
