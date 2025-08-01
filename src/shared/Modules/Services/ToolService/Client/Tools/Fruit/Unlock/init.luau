local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PopupClient = require(Services.PopupService.Client)
local BaseClient = require(Services.BaseService.Client)
local Base = require(Services.BaseService.Client.Base)

local UnlockMenu = require(script.UnlockMenu)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)

local scoped, peek = Fusion.scoped, Fusion.peek

local useFruitAttempt = Net:RemoteFunction("UseFruitAttempt")

local UnlockFruit = {}
UnlockFruit.__index = UnlockFruit

type self = {
	player: Player,
	tool: Tool,

	unlockMenu: ScreenGui?,

	playerBases: Fusion.Value<{ Base.Base }, any>,

	_trove: Trove.Trove,
	_scope: Fusion.Scope<any>,
}
export type UnlockFruit = typeof(setmetatable({} :: self, UnlockFruit))

function UnlockFruit.new(player: Player, tool: Tool): UnlockFruit
	local self = setmetatable({}, UnlockFruit) :: UnlockFruit

	self._trove = Trove.new()
	self._scope = scoped(Fusion)

	self.playerBases = self._scope:Value({})

	local function removeBase(base: Base.Base)
		local playerBasesState = table.clone(peek(self.playerBases))
		local i = table.find(playerBasesState, base)
		if i then
			table.remove(playerBasesState, i)
		end
		self.playerBases:set(playerBasesState)
	end

	local baseObservers = {}
	local function baseAdded(base: Base.Base)
		baseObservers[base.Id] = self._scope:Observer(base.locked):onBind(function()
			if peek(base.locked) and peek(base.Owner) ~= player.UserId then
				local playerBasesState = table.clone(peek(self.playerBases))
				table.insert(playerBasesState, base)
				self.playerBases:set(playerBasesState)
			else
				removeBase(base)
			end
		end)
	end
	for _, v in BaseClient.bases do
		baseAdded(v)
	end
	self._trove:Add(BaseClient.baseLoaded:Connect(function(base: Base.Base)
		if peek(base.Owner) == Players.LocalPlayer.UserId then
			return
		end
		if not baseObservers[base.Id] then
			baseAdded(base)
		end
	end))
	self._trove:Add(BaseClient.baseReset:Connect(function(base: Base.Base)
		if baseObservers[base.Id] then
			baseObservers[base.Id]()
		end
		removeBase(base)
	end))

	self.player = player
	self.tool = tool

	return self
end

function UnlockFruit.Equipped(self: UnlockFruit): ()
	if self.unlockMenu then
		self.unlockMenu:Destroy()
		self.unlockMenu = nil
	end

	self.unlockMenu = UnlockMenu(self._scope, {
		playerBases = self.playerBases,
		baseSelected = function(base: Base.Base)
			print(base)
			local success = useFruitAttempt:InvokeServer(self.tool, {
				baseId = base.Id,
			})
			print(success)
			if success then
				local ownerId = peek(base.Owner)
				if not ownerId then
					return
				end
				local player = Players:GetPlayerByUserId(ownerId)
				if not player then
					return
				end
				PopupClient.AddPopup({
					message = `Unlocked {player.DisplayName}'s Base!`,
					gradient = ReplicatedStorage.Assets.Templates.Gui.Gradients.Ice,
				})
			end
		end,
	})
	self.unlockMenu.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function UnlockFruit.Unequipped(self: UnlockFruit): ()
	if self.unlockMenu then
		self.unlockMenu:Destroy()
		self.unlockMenu = nil
	end
end

function UnlockFruit.Activated(self: UnlockFruit): () end

function UnlockFruit.Destroy(self: UnlockFruit): ()
	self._scope:doCleanup()
end

return UnlockFruit
