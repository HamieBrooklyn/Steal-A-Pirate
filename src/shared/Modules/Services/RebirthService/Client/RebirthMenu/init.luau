local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gradients = ReplicatedStorage.Assets.Templates.Gui.Gradients
local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services

local SpawningClient = require(Services.SpawningService.Client)
local PlayerDataClient = require(Services.PlayerDataService.Client)
local BaseClient = require(Services.BaseService.Client)

local Platform = require(Services.BaseService.Client.Base.Platform)
local Base = require(Services.BaseService.Client.Base)
local SharedBaseData = require(Services.BaseService.Data)
local SharedToolData = require(Services.ToolService.Data)

local abbreviateNumber = require(Modules.Utilities.abbreviateNumber)
local formatTime = require(Modules.Utilities.formatTime)

local SharedSpawningData = require(Services.SpawningService.Data)
local SharedData = require(script.Parent.Parent.Data)

local CharacterFrame = require(script.CharacterFrame)
local RewardFrame = require(script.RewardFrame)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Gradiented = require(Modules.Classes.Gradiented)
local Particle = require(Modules.Classes.Particle)
local Sound = require(Modules.Classes.Sound)
local Charm = require(ReplicatedStorage.Packages.Charm)

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local scoped, peek = Fusion.scoped, Fusion.peek
local atom, subscribe = Charm.atom, Charm.subscribe

local RebirthAttempt = Net:RemoteFunction("RebirthAttempt")

local RebirthMenu = {}
RebirthMenu.__index = RebirthMenu

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	rootSeed: Fusion.Value<number?, any>,
	rebirths: Fusion.Value<number?, any>,

	CashVal: Fusion.Value<NumberValue?, any>,
	Cash: Fusion.Value<number?, any>,

	CashRequiredText: Fusion.Value<string, any>,

	hasEnoughCash: Fusion.Value<boolean, any>,
	ownsAllCharacters: Fusion.Value<boolean, any>,

	canRebirth: Fusion.Computed<boolean>,
	checkProgress: Fusion.Computed<any>,

	random: Fusion.Value<Random?, any>,

	seed: Fusion.Computed<number?>,
	rebirthLevelData: Fusion.Computed<RebirthLevel?>,

	menuShown: Fusion.Value<boolean, any>,
}
export type RebirthMenu = typeof(setmetatable({} :: self, RebirthMenu))
export type RebirthLevel = {
	CashRequired: number,
	Characters: { string },
}

function RebirthMenu.new(menu: ScreenGui, rebirths: Fusion.Value<number, any>): RebirthMenu
	local self = setmetatable({}, RebirthMenu) :: RebirthMenu

	self.scope = scoped(Fusion, {
		RewardFrame = RewardFrame,
	}) :: Fusion.Scope<any>
	self.trove = Trove.new()

	self.rootSeed = self.scope:Value(nil) :: Fusion.Value<number?, any>
	self.rebirths = rebirths :: Fusion.Value<number?, any>

	self.CashVal = self.scope:Value(nil) :: Fusion.Value<NumberValue?, any>
	--self.Cash = self.scope:Value(nil) :: Fusion.Value<number?, any>

	self.CashRequiredText = self.scope:Value("") :: Fusion.Value<string, any>

	self.hasEnoughCash = self.scope:Value(false) :: Fusion.Value<boolean, any>
	self.ownsAllCharacters = self.scope:Value(false) :: Fusion.Value<boolean, any>

	local requiredCharacters = self.scope:Value({})

	self.menuShown = self.scope:Value(false) :: Fusion.Value<boolean, any>

	self.canRebirth = self.scope:Computed(function(use)
		return use(self.hasEnoughCash) and use(self.ownsAllCharacters)
	end)
	self.checkProgress = self.scope:Computed(function(use)
		local progress = 0

		local CashState: number? = use(PlayerDataClient.leaderstats.Cash)
		local levelDataState: RebirthLevel? = use(self.rebirthLevelData)

		if CashState then
			-- local requiredCharactersState = use(requiredCharacters)

			-- local totalItems = 0
			-- local fulfilled = 0
			-- for _, v in requiredCharactersState do
			-- 	totalItems += 1
			-- 	if v == true then
			-- 		fulfilled += 1
			-- 	end
			-- end

			local CashProgress = math.clamp(
				(
					CashState
					/ (
						levelDataState and levelDataState.CashRequired
						or (SharedData.Constants.OverCost * (use(self.rebirths) * SharedData.Constants.OverCostMult))
					)
				),
				0,
				1
			)

			local required = levelDataState and levelDataState.CashRequired
				or SharedData.Constants.OverCost * (peek(self.rebirths) * SharedData.Constants.OverCostMult)
			self.hasEnoughCash:set(CashState >= required)

			-- local itemProgress = if totalItems > 0 then fulfilled / totalItems else 0
			-- local finalProgress = (CashProgress + itemProgress) / 2

			progress = CashProgress
		end

		return progress
	end)

	-- Loading and updating characters as they are added or removed:
	local function checkOwnedCharacters()
		BaseClient:GetBase():andThen(function(base: Base.Base)
			local foundCharacters = {}
			for _, v in base.Platforms do
				local charName = peek(v.CharacterName)
				if not charName then
					continue
				end
				table.insert(foundCharacters, charName)
			end

			local requiredCharactersState = peek(requiredCharacters)
			for i, _ in requiredCharactersState do
				requiredCharactersState[i] = table.find(foundCharacters, i) ~= nil
			end
			requiredCharacters:set(requiredCharactersState)

			--print(requiredCharactersState)
			local hasAll = true
			for _, v in requiredCharactersState do
				if not v then
					hasAll = false
				end
			end
			self.ownsAllCharacters:set(hasAll)
		end)
	end
	BaseClient:GetBase():andThen(function(base: Base.Base)
		-- self.trove:Add(BaseClient.characterAddedToBase:Connect(checkOwnedCharacters))
		-- self.trove:Add(BaseClient.characterRemovedFromBase:Connect(checkOwnedCharacters))
		-- self.trove:Add(BaseClient.baseLoaded:Connect(checkOwnedCharacters))
		-- self.trove:Add(BaseClient.baseReset:Connect(checkOwnedCharacters))
		-- self.trove:Add(BaseClient.platformsReset:Connect(checkOwnedCharacters))
		for _, v in base.Platforms do
			self.scope:Observer(v.CharacterName):onBind(checkOwnedCharacters)
		end
		checkOwnedCharacters()
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("ProfileLoaded"):Connect(checkOwnedCharacters)

	self.random = self.scope:Value(nil) :: Fusion.Value<Random?, any>

	local CashChangeCleanup: (() -> ())?
	self.scope:Observer(self.CashVal):onChange(function()
		if CashChangeCleanup then
			CashChangeCleanup()
			CashChangeCleanup = nil
		end

		local CashValState: NumberValue? = peek(self.CashVal)
		if CashValState then
			CashChangeCleanup = self.trove:Add(Observers.observeProperty(CashValState, "Value", function(value)
				--self.Cash:set(value)

				--[[ local levelDataState: RebirthLevel = peek(self.rebirthLevelData)
				local required = levelDataState and levelDataState.CashRequired
					or SharedData.Constants.OverCost * (peek(self.rebirths) * SharedData.Constants.OverCostMult)
				self.hasEnoughCash:set(value >= required) ]]
				return function() end
			end))
		end
	end)

	self.CashRequiredText = self.scope:Computed(function(use)
		local levelDataState: RebirthLevel = use(self.rebirthLevelData)
		local required = levelDataState and levelDataState.CashRequired
			or SharedData.Constants.OverCost * (use(self.rebirths) * SharedData.Constants.OverCostMult)
		return `{abbreviateNumber(use(PlayerDataClient.leaderstats.Cash))}/{abbreviateNumber(required)}`
	end)
	self.seed = self.scope:Computed(function(use)
		local rootSeedState = use(self.rootSeed)
		local rebirthsState = use(self.rebirths)
		if rootSeedState and rebirthsState then
			return rootSeedState + rebirthsState
		end
	end)
	self.rebirthLevelData = self.scope:Computed(function(use)
		local rebirthsState = use(self.rebirths)
		if rebirthsState then
			return SharedData.Levels[use(rebirthsState) + 1]
		end
	end)

	self.scope:Observer(self.seed):onBind(function()
		local seedState: number? = peek(self.seed)
		if not seedState then
			return
		end

		requiredCharacters:set({})

		local rnd = Random.new(seedState)
		self.random:set(rnd)

		local levelDataState: RebirthLevel = peek(self.rebirthLevelData)

		local function obtainable(charName: string)
			return SharedSpawningData.Characters.Info[charName].Natural == true
				or SharedSpawningData.Characters.Info[charName].Natural == nil
		end

		if levelDataState then
			local chosenCharacters = {}
			for _, v in levelDataState.Characters do
				local charactersWithRarity = SpawningClient.characterNamesByRarity[v]
				local tries = 0
				local charName: string
				repeat
					charName = charactersWithRarity[rnd:NextInteger(1, #charactersWithRarity)]
					tries += 1
				until obtainable(charName) and (chosenCharacters[charName] == nil or tries > 100)
				chosenCharacters[charName] = false
			end
			requiredCharacters:set(chosenCharacters)

			checkOwnedCharacters()
		end
	end)

	local mainFrame: Frame = menu:WaitForChild("Main")
	local rewardsFrame: Frame = mainFrame:WaitForChild("Rewards")
	local requirementsFrame: Frame = mainFrame:WaitForChild("Requirements")
	local rebirthButton: TextButton = mainFrame:WaitForChild("Rebirth")

	-- Managing requirements:
	local CashRequiredLabel: TextLabel = requirementsFrame:WaitForChild("CashRequired")
	local startTextColor = CashRequiredLabel.TextColor3

	self.scope:Hydrate(CashRequiredLabel)({
		Text = self.CashRequiredText,
		TextColor3 = self.scope:Tween(
			self.scope:Computed(function(use)
				return use(self.hasEnoughCash) and Color3.new(0, 1, 0) or startTextColor
			end),
			TweenInfo.new(0.5)
		),
	})

	local shownValues: { Fusion.Value<boolean, any> } = {}
	self.scope:Hydrate(requirementsFrame:WaitForChild("Contents"))({
		[Children] = self.scope:ForPairs(requiredCharacters, function(_, scope, name, owned)
			local shown = scope:Value(mainFrame.Visible)
			table.insert(shownValues, shown)

			return name, CharacterFrame(scope, {
				characterName = name,
				owned = owned,
				shown = shown,
			})
		end),
	})
	self.trove:Add(Observers.observeProperty(mainFrame, "Visible", function(visible)
		self.menuShown:set(visible)
		task.spawn(function()
			for _, v in shownValues do
				v:set(visible)
				if visible then
					task.wait(0.05)
				end
			end
		end)
		return function() end
	end))

	-- Updating progress bar:
	self.scope:Hydrate(requirementsFrame:WaitForChild("ProgressBar"):WaitForChild("Fill"))({
		Size = self.scope:Spring(
			self.scope:Computed(function(use)
				return use(self.menuShown) and UDim2.fromScale(use(self.checkProgress), 1) or UDim2.fromScale(0, 1)
			end),
			25,
			0.9
		),
	})
	self.scope:Hydrate(requirementsFrame:WaitForChild("ProgressBar"):WaitForChild("BackFill"))({
		Size = self.scope:Spring(
			self.scope:Computed(function(use)
				return use(self.menuShown) and UDim2.fromScale(use(self.checkProgress), 1) or UDim2.fromScale(0, 1)
			end),
			10,
			0.9
		),
	})

	-- Managing rewards:
	self.scope:RewardFrame({
		titleText = "Starting Cash",
		infoText = self.scope:Computed(function(use)
			local rebirthsState: number? = use(self.rebirths)
			return rebirthsState and `${abbreviateNumber(SharedData.Constants.StartingCash * (rebirthsState + 1))}`
				or ""
		end),
		titleGradient = Gradients.Apple,
		infoTextColor = Color3.new(0, 1, 0),
	}).Parent =
		rewardsFrame:WaitForChild("Contents")
	self.scope:RewardFrame({
		titleText = "Cash Multiplier",
		infoText = self.scope:Computed(function(use)
			local rebirthsState: number? = use(self.rebirths)
			return rebirthsState and `x{SharedData.Constants.CashMultiplier * (rebirthsState + 1)}` or ""
		end),
		titleGradient = Gradients.Banana,
		infoTextColor = Color3.new(1, 1, 0),
	}).Parent =
		rewardsFrame:WaitForChild("Contents")
	self.scope:RewardFrame({
		titleText = "Lock Timer",
		infoText = self.scope:Computed(function(use)
			local rebirthsState: number? = use(self.rebirths)
			return rebirthsState
					and formatTime(
						SharedBaseData.LockedDuration + SharedData.Constants.LockTimerIncrement * (rebirthsState + 1),
						{
							mode = "text",
						}
					)
				or ""
		end),
		shown = self.scope:Computed(function(use)
			local rebirthsState: number? = use(self.rebirths)
			return use(rebirthsState + 1) < SharedData.Constants.LockTimerMaxMult
		end),
		titleGradient = Gradients.RipeBanana,
		infoTextColor = Color3.new(1, 1, 0),
	}).Parent =
		rewardsFrame:WaitForChild("Contents")

	local toolNamesByRequiredRebirths = {}
	for i, v in SharedToolData.ShopTools do
		toolNamesByRequiredRebirths[v.RebirthsRequired] = i
	end
	self.scope:RewardFrame({
		shown = self.scope:Computed(function(use)
			return toolNamesByRequiredRebirths[use(self.rebirths) + 1]
		end),
		image = self.scope:Computed(function(use)
			local toolName = toolNamesByRequiredRebirths[use(self.rebirths) + 1]
			return toolName and SharedToolData.ShopTools[toolName].Image or ""
		end),
	}).Parent =
		rewardsFrame:WaitForChild("Contents")

	local particle = Particle.new(ReplicatedStorage.Assets.VFX.Particles.Rebirth, Vector3.zero)

	-- Updating rebirth button:
	self.scope:Hydrate(rebirthButton)({
		Text = self.scope:Computed(function(use)
			return use(self.canRebirth) and "REBIRTH!" or "UNABLE."
		end),
		Interactable = self.canRebirth,
		[OnEvent("MouseButton1Click")] = function()
			if peek(self.canRebirth) then
				local success = RebirthAttempt:InvokeServer()
				if success then
					self.rebirths:set(peek(self.rebirths) + 1)

					local char = Players.LocalPlayer.Character
					if char then
						particle.part:PivotTo(char:GetPivot())
						particle:Emit()
					end

					Sound.new(ReplicatedStorage.Assets.Sounds.SoundEffects.Rebirth, workspace):Play()
				end
			end
		end,
	})
	local rebirthGradient: Gradiented.Gradiented = self.trove:Add(Gradiented.new(rebirthButton))
	self.scope:Observer(self.canRebirth):onBind(function()
		rebirthGradient.gradient:set(peek(self.canRebirth) and Gradients.Banana or Gradients.Rock)
	end)

	return self
end

function RebirthMenu.Destroy(self: RebirthMenu): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return RebirthMenu
