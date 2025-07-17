local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gradients = ReplicatedStorage.Assets.Templates.Gui.Gradients
local Modules = ReplicatedStorage.Shared.Modules
local Services = Modules.Services

local SpawningClient = require(Services.SpawningService.Client)
local BaseClient = require(Services.BaseService.Client)

local Platform = require(Services.BaseService.Client.Base.Platform)
local Base = require(Services.BaseService.Client.Base)
local SharedBaseData = require(Services.BaseService.Data)
local SharedToolData = require(Services.ToolService.Data)

local abbreviateNumber = require(Modules.Utilities.abbreviateNumber)
local formatTime = require(Modules.Utilities.formatTime)

local SharedData = require(script.Parent.Parent.Data)
local CharacterFrame = require(script.CharacterFrame)
local RewardFrame = require(script.RewardFrame)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Gradiented = require(Modules.Classes.Gradiented)

local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local scoped, peek = Fusion.scoped, Fusion.peek

local RebirthAttempt = Net:RemoteFunction("RebirthAttempt")

local RebirthMenu = {}
RebirthMenu.__index = RebirthMenu

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	rootSeed: Fusion.Value<number?, any>,
	rebirths: Fusion.Value<number?, any>,

	BeliVal: Fusion.Value<NumberValue?, any>,
	Beli: Fusion.Value<number?, any>,

	BeliRequiredText: Fusion.Value<string, any>,

	hasEnoughBeli: Fusion.Value<boolean, any>,
	ownsAllCharacters: Fusion.Value<boolean, any>,

	charactersRequiredNames: Fusion.Value<{ string }, any>,
	ownedCharacters: Fusion.Value<{ string }, any>,
	requiredCharactersUnlocked: Fusion.Value<{ string }, any>,

	canRebirth: Fusion.Computed<boolean>,
	checkProgress: Fusion.Computed<any>,

	random: Fusion.Value<Random?, any>,

	seed: Fusion.Computed<number?>,
	rebirthLevelData: Fusion.Computed<RebirthLevel?>,

	menuShown: Fusion.Value<boolean, any>,
}
export type RebirthMenu = typeof(setmetatable({} :: self, RebirthMenu))
export type RebirthLevel = {
	BeliRequired: number,
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

	self.BeliVal = self.scope:Value(nil) :: Fusion.Value<NumberValue?, any>
	self.Beli = self.scope:Value(nil) :: Fusion.Value<number?, any>

	self.BeliRequiredText = self.scope:Value("") :: Fusion.Value<string, any>

	self.hasEnoughBeli = self.scope:Value(false) :: Fusion.Value<boolean, any>
	self.ownsAllCharacters = self.scope:Value(false) :: Fusion.Value<boolean, any>

	self.charactersRequiredNames = self.scope:Value({}) :: Fusion.Value<{ string }, any>
	self.ownedCharacters = self.scope:Value({}) :: Fusion.Value<{ string }, any>
	self.requiredCharactersUnlocked = self.scope:Value({}) :: Fusion.Value<{ string }, any>

	self.menuShown = self.scope:Value(false) :: Fusion.Value<boolean, any>

	self.canRebirth = self.scope:Computed(function(use)
		return use(self.hasEnoughBeli) and use(self.ownsAllCharacters)
	end)
	self.checkProgress = self.scope:Computed(function(use)
		local progress = 0

		local BeliState: number? = use(self.Beli)
		local levelDataState: RebirthLevel? = peek(self.rebirthLevelData)

		if BeliState then
			local fulfilled = 0
			local totalItems = #use(self.charactersRequiredNames)

			local reqCharsUnlockedState = use(self.requiredCharactersUnlocked)
			for _, itemName in ipairs(reqCharsUnlockedState) do
				if table.find(reqCharsUnlockedState, itemName) then
					fulfilled += 1
				end
			end

			local BeliProgress = math.clamp(
				(BeliState / (levelDataState and levelDataState.BeliRequired or SharedData.Constants.OverCost)),
				0,
				1
			)

			local itemProgress = if totalItems > 0 then fulfilled / totalItems else 0
			local finalProgress = (BeliProgress + itemProgress) / 2

			progress = finalProgress
		end

		return progress
	end)

	-- Loading and updating characters as they are added or removed:
	self.trove:Add(
		BaseClient.characterAddedToBase:Connect(
			function(sentBase: Base.Base, characterName: string, platform: Platform.Platform)
				BaseClient.GetBase():andThen(function(base: Base.Base)
					if base.Id == sentBase.Id then
						local ownedCharsState = peek(self.ownedCharacters)
						table.insert(ownedCharsState, characterName)
						if
							table.find(peek(self.charactersRequiredNames), characterName)
							and not table.find(peek(self.requiredCharactersUnlocked), characterName)
						then
							local requiredCharsUnlockedState = peek(self.requiredCharactersUnlocked)
							table.insert(requiredCharsUnlockedState, characterName)
							self.requiredCharactersUnlocked:set(requiredCharsUnlockedState)
						end
						self.ownedCharacters:set(ownedCharsState)

						self.ownsAllCharacters:set(
							#peek(self.requiredCharactersUnlocked) == #peek(self.charactersRequiredNames)
						)
					end
				end)
			end
		)
	)
	self.trove:Add(
		BaseClient.characterRemovedFromBase:Connect(
			function(sentBase: Base.Base, characterName: string, platform: Platform.Platform)
				BaseClient.GetBase():andThen(function(base: Base.Base)
					if base.Id == sentBase.Id then
						local ownedCharsState = peek(self.ownedCharacters)
						table.remove(ownedCharsState, table.find(ownedCharsState, characterName))
						self.ownedCharacters:set(ownedCharsState)

						local requiredCharsUnlockedState = peek(self.requiredCharactersUnlocked)
						local i = table.find(requiredCharsUnlockedState, characterName)
						if i then
							table.remove(requiredCharsUnlockedState, i)
							self.requiredCharactersUnlocked:set(requiredCharsUnlockedState)
							self.ownsAllCharacters:set(
								#peek(self.requiredCharactersUnlocked) == #peek(self.charactersRequiredNames)
							)
						end
					end
				end)
			end
		)
	)

	self.random = self.scope:Value(nil) :: Fusion.Value<Random?, any>

	local BeliChangeCleanup: (() -> ())?
	self.scope:Observer(self.BeliVal):onChange(function()
		if BeliChangeCleanup then
			BeliChangeCleanup()
			BeliChangeCleanup = nil
		end

		local BeliValState: NumberValue? = peek(self.BeliVal)
		if BeliValState then
			BeliChangeCleanup = self.trove:Add(Observers.observeProperty(BeliValState, "Value", function(value)
				self.Beli:set(value)

				local levelDataState: RebirthLevel = peek(self.rebirthLevelData)
				local required = levelDataState and levelDataState.BeliRequired or SharedData.Constants.OverCost
				self.hasEnoughBeli:set(value >= required)
				self.BeliRequiredText:set(`{abbreviateNumber(value)}/{abbreviateNumber(required)}`)
				return function() end
			end))
		end
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

		self.requiredCharactersUnlocked:set({})
		self.charactersRequiredNames:set({})

		local rnd = Random.new(seedState)
		self.random:set(rnd)

		local levelDataState: RebirthLevel = peek(self.rebirthLevelData)

		if levelDataState then
			local chosenCharacterNames = {}
			for _, v in levelDataState.Characters do
				local charactersWithRarity = SpawningClient.characterNamesByRarity[v]
				local tries = 0
				local charName: string
				repeat
					charName = charactersWithRarity[rnd:NextInteger(1, #charactersWithRarity)]
					tries += 1
				until table.find(chosenCharacterNames, charName) == nil or tries > 100
				table.insert(chosenCharacterNames, charName)
			end
			self.charactersRequiredNames:set(chosenCharacterNames)
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
				return use(self.hasEnoughBeli) and Color3.new(0, 1, 0) or startTextColor
			end),
			TweenInfo.new(0.5)
		),
	})

	local shownValues: { Fusion.Value<boolean, any> } = {}
	self.scope:Hydrate(requirementsFrame:WaitForChild("Contents"))({
		[Children] = self.scope:ForValues(self.charactersRequiredNames, function(_, scope, name)
			local shown = scope:Value(mainFrame.Visible)
			table.insert(shownValues, shown)

			return CharacterFrame(scope, {
				ownedCharacters = self.ownedCharacters,
				characterName = name,
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
		titleText = "Starting Beli",
		infoText = self.scope:Computed(function(use)
			local rebirthsState: number? = use(self.rebirths)
			return rebirthsState and `${abbreviateNumber(SharedData.Constants.StartingBeli * (rebirthsState + 1))}`
				or ""
		end),
		titleGradient = Gradients.Apple,
		infoTextColor = Color3.new(0, 1, 0),
	}).Parent =
		rewardsFrame:WaitForChild("Contents")
	self.scope:RewardFrame({
		titleText = "Beli Multiplier",
		infoText = self.scope:Computed(function(use)
			local rebirthsState: number? = use(self.rebirths)
			return rebirthsState and `x{SharedData.Constants.BeliMultiplier * (rebirthsState + 1)}` or ""
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
